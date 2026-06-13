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
                        // Demo/automation hook: skip onboarding and force a fresh score.
                        model.hasOnboarded = true
                        await model.runScore()
                    } else {
                        // Ambient: refresh quietly if the last forecast is stale.
                        await model.refreshIfStale()
                    }
                }
        }
    }
}
