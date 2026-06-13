import Foundation
import BackgroundTasks
import UserNotifications

/// Runs the forecast daily in the background, writes the result to SharedStore
/// (so Siri reads it with the app closed), and notifies the patient on elevated risk.
enum DailyScoreTask {
    static let identifier = "com.crisisforecaster.app.dailyScore"

    /// Must be called before the app finishes launching (from App.init).
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGProcessingTask else { return }
            handle(task)
        }
    }

    /// Ask the system to run us roughly daily.
    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 20, to: Date())
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGProcessingTask) {
        schedule() // chain the next run

        // BGProcessingTask isn't Sendable yet, but completing it after an await is
        // safe — the framework's completion call is internally thread-safe.
        nonisolated(unsafe) let task = task
        let work = Task {
            let result = await runForecast()
            task.setTaskCompleted(success: result)
        }
        task.expirationHandler = { work.cancel() }
    }

    /// Self-contained scoring path (no AppModel — this runs off the main actor).
    static func runForecast() async -> Bool {
        let demoMode = UserDefaults.standard.bool(forKey: "demoMode")
        let health: HealthDataSource = demoMode ? DemoHealthSource() : LiveHealthSource()
        let weatherProvider: WeatherProvider = demoMode ? DemoWeatherProvider() : WeatherKitService()
        let claude = ClaudeClient()
        let engine = RiskEngine(claude: claude)
        let store = SharedStore()
        let profile = store.loadProfile() ?? .demo

        do {
            let vitals = try await health.recentVitals(days: 14)
            let weather = try await weatherProvider.currentWeather()
            let snapshot = try await engine.score(profile: profile, vitals: vitals, weather: weather)
            try? store.saveRisk(snapshot)

            if snapshot.riskLevel.isElevated {
                if let passport = try? await PassportService(claude: claude).draft(profile: profile, risk: snapshot) {
                    try? store.savePassport(passport)
                }
                await notify(snapshot)
            }
            return true
        } catch {
            return false
        }
    }

    private static func notify(_ snapshot: RiskSnapshot) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(snapshot.riskLevel.title) crisis risk"
        content.body = snapshot.explanation
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
