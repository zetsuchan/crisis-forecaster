import Foundation
import Observation
import WidgetKit

/// App-wide state and the orchestration entry point the UI, the background task,
/// and (indirectly, via SharedStore) the Siri intents all flow through.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case idle
        case scoring
        case failed(String)
    }

    /// Persisted toggle: Demo Mode replays the scripted decline; Live Mode reads
    /// HealthKit + WeatherKit. Demo is the default for a reliable stage demo.
    var demoMode: Bool {
        didSet { defaults.set(demoMode, forKey: Self.demoModeKey) }
    }

    /// First-launch onboarding gate.
    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: Self.onboardedKey) }
    }

    var profile: PatientProfile {
        didSet { try? store.saveProfile(profile) }
    }

    /// The vitals behind the latest forecast — drives the trend view so the
    /// forecast is visibly grounded in the body's data.
    var vitals: [VitalsSnapshot] = []
    var risk: RiskSnapshot?
    var passport: EmergencyPassport?
    var phase: Phase = .idle

    /// Patient self-reports, most recent first. Folds into the forecast + passport.
    var checkIns: [CheckIn] = []
    var latestCheckIn: CheckIn? { checkIns.first }

    /// Result of the on-device (Apple Intelligence) triage of the latest check-in.
    var lastTriage: TriageResult?

    /// Which tab is showing (lets the Today CTA jump to Check-in).
    var selectedTab: String = "today"

    /// Recommended actions the patient has checked off for the current forecast.
    var completedActions: Set<String> = []

    private let store = SharedStore()
    private let defaults = UserDefaults.standard
    private static let demoModeKey = "demoMode"
    private static let onboardedKey = "hasOnboarded"

    /// A forecast older than this (or missing) triggers an ambient refresh on open.
    private static let staleInterval: TimeInterval = 12 * 3600

    init() {
        if defaults.object(forKey: Self.demoModeKey) == nil {
            defaults.set(true, forKey: Self.demoModeKey)
        }
        demoMode = defaults.bool(forKey: Self.demoModeKey)
        hasOnboarded = defaults.bool(forKey: Self.onboardedKey)
        profile = store.loadProfile() ?? .demo
        risk = store.loadRisk()
        passport = store.loadPassport()
        checkIns = store.loadCheckIns()
        if ProcessInfo.processInfo.arguments.contains("-openPassport") {
            selectedTab = "passport"
        }
    }

    /// Toggle a recommended action's done state for the current forecast.
    func toggleAction(_ action: String) {
        if completedActions.contains(action) { completedActions.remove(action) }
        else { completedActions.insert(action) }
    }

    /// Record a self-report. The on-device Apple model triages it first (private,
    /// instant); then Claude re-runs the full forecast informed by that digest.
    func addCheckIn(_ checkIn: CheckIn) async {
        checkIns.insert(checkIn, at: 0)
        try? store.saveCheckIns(checkIns)
        lastTriage = await OnDeviceTriage().assess(checkIn: checkIn, profile: profile)
        await runScore()
    }

    private var healthSource: HealthDataSource {
        demoMode ? DemoHealthSource() : LiveHealthSource()
    }

    private var weatherProvider: WeatherProvider {
        demoMode ? DemoWeatherProvider() : WeatherKitService()
    }

    var isForecastStale: Bool {
        guard let risk else { return true }
        return Date().timeIntervalSince(risk.generatedAt) > Self.staleInterval
    }

    /// Ambient entry point: refresh on open if we have nothing fresh to show.
    func refreshIfStale() async {
        guard hasOnboarded, isForecastStale, phase != .scoring else { return }
        await runScore()
    }

    /// The full daily loop: gather data, score, persist, and on elevated risk stage
    /// the passport.
    func runScore() async {
        phase = .scoring
        let engine = RiskEngine(claude: ClaudeClient())
        do {
            let gathered = try await healthSource.recentVitals(days: 14)
            let weather = try await weatherProvider.currentWeather()
            vitals = gathered

            let snapshot = try await engine.score(profile: profile, vitals: gathered, weather: weather, checkIn: latestCheckIn, triageNote: lastTriage?.summary)
            risk = snapshot
            completedActions = []  // fresh forecast → fresh checklist
            try? store.saveRisk(snapshot)
            WidgetCenter.shared.reloadAllTimelines()  // update the Home/Lock Screen widget now

            if snapshot.riskLevel.isElevated {
                let drafted = try await PassportService(claude: ClaudeClient()).draft(profile: profile, risk: snapshot, checkIn: latestCheckIn)
                passport = drafted
                try? store.savePassport(drafted)
            }
            phase = .idle
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Manually (re)stage the passport regardless of current risk band.
    func stagePassport() async {
        guard let risk else { return }
        do {
            let drafted = try await PassportService(claude: ClaudeClient()).draft(profile: profile, risk: risk, checkIn: latestCheckIn)
            passport = drafted
            try? store.savePassport(drafted)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Wipe everything and return to a fresh onboarding (for clean demo recordings).
    func resetAll() {
        store.clearAll()
        defaults.removeObject(forKey: Self.onboardedKey)
        defaults.removeObject(forKey: Self.demoModeKey)
        risk = nil
        passport = nil
        checkIns = []
        lastTriage = nil
        vitals = []
        profile = .demo
        demoMode = true
        phase = .idle
        hasOnboarded = false
    }

    /// Called at the end of onboarding: persist choices, then run the first forecast.
    func completeOnboarding(profile: PatientProfile, demoMode: Bool) async {
        self.profile = profile
        self.demoMode = demoMode
        hasOnboarded = true
        await runScore()
    }
}
