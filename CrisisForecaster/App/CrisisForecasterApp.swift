import SwiftUI

@main
struct CrisisForecasterApp: App {
    @State private var model = AppModel()

    init() {
        DailyScoreTask.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    DailyScoreTask.schedule()
                    if ProcessInfo.processInfo.arguments.contains("-autorunForecast") {
                        // Demo/automation hook: skip onboarding and exercise the full
                        // dual-model flow (on-device triage → Claude forecast) via a
                        // sample check-in.
                        model.hasOnboarded = true
                        await model.addCheckIn(CheckIn(
                            painLevel: 6,
                            painLocations: ["Back", "Legs"],
                            hydration: .low,
                            notes: "Aching more than usual since the cold came in."
                        ))
                    } else {
                        // Ambient: refresh quietly if the last forecast is stale.
                        await model.refreshIfStale()
                    }
                }
        }
    }
}
