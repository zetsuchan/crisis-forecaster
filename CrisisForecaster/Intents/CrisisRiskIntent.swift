import AppIntents

/// "What's my crisis risk this week?" — answered from the last forecast in
/// SharedStore, so Siri responds instantly with the app closed (no network call
/// in the intent path).
struct CrisisRiskIntent: AppIntent {
    static let title: LocalizedStringResource = "Check crisis risk"
    static let description = IntentDescription(
        "Reports your latest vaso-occlusive crisis risk and why.",
        categoryName: "Health"
    )
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let risk = SharedStore().loadRisk() else {
            return .result(dialog: "I don't have a forecast yet. Open Crisis Forecaster and run one.")
        }
        let dialog = "\(risk.riskLevel.title) crisis risk for the next \(risk.windowHours) hours. \(risk.explanation)"
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}
