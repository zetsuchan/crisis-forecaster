import AppIntents

/// "Show my sickle cell passport" — surfaces the staged ER handoff packet. Opens
/// the app to the Passport tab so it's on screen in the ER moment.
struct ShowPassportIntent: AppIntent {
    static let title: LocalizedStringResource = "Show sickle cell passport"
    static let description = IntentDescription(
        "Shows your staged Emergency Department handoff packet.",
        categoryName: "Health"
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if SharedStore().loadPassport() != nil {
            return .result(dialog: "Here's your sickle cell Emergency Passport.")
        } else {
            return .result(dialog: "No passport is staged yet. Open Crisis Forecaster to stage one.")
        }
    }
}
