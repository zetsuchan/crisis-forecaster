import Foundation
import FoundationModels
import ClaudeForFoundationModels

/// Routes the Claude Opus 4.8 forecast **through Apple's Foundation Models framework**
/// using Anthropic's `ClaudeForFoundationModels` package. Claude is driven with the same
/// `LanguageModelSession` API as Apple's on-device model — one interface, `@Generable`
/// structured output, requests going straight from the app to the Anthropic API.
///
/// This is the iOS 27 "bring an LLM provider to Foundation Models" path. The raw-URLSession
/// `RiskEngine` remains as a fallback (see `AppModel.runScore`).
struct FoundationModelsForecaster: Sendable {

    /// Guided-generation schema — the same shape as `RiskSnapshot`, produced via
    /// Foundation Models structured output.
    @Generable
    struct Forecast {
        @Guide(description: "One of: low, guarded, elevated, high")
        var riskLevel: String
        @Guide(description: "Risk score from 0 to 100 (whole number, not a 0-1 fraction)")
        var score: Int
        @Guide(description: "Forecast horizon in hours, 24 to 72")
        var windowHours: Int
        var drivers: [Driver]
        @Guide(description: "Warm, plain-language explanation of the risk and why")
        var explanation: String
        @Guide(description: "Concrete self-management actions")
        var actions: [String]
    }

    @Generable
    struct Driver {
        @Guide(description: "The signal, e.g. 'Barometric pressure'")
        var factor: String
        @Guide(description: "What it's doing, e.g. 'dropping 15mb overnight'")
        var detail: String
        @Guide(description: "How the metric moved: one of up, down, steady")
        var direction: String
        @Guide(description: "One short sentence on why this matters for THIS patient")
        var impact: String
    }

    func score(
        profile: PatientProfile,
        vitals: [VitalsSnapshot],
        weather: WeatherSnapshot,
        checkIn: CheckIn? = nil,
        triageNote: String? = nil
    ) async throws -> RiskSnapshot {
        guard let key = Self.apiKey else { throw ClaudeClient.ClaudeError.missingAPIKey }

        // Claude, behind Apple's Foundation Models LanguageModelSession.
        let model = ClaudeLanguageModel(name: .opus4_8, auth: .apiKey(key), fixedEffort: .medium)
        let session = LanguageModelSession(model: model, instructions: RiskEngine.systemPrompt)

        let user = RiskEngine.buildUserMessage(
            vitals: vitals, weather: weather, profile: profile,
            checkIn: checkIn, triageNote: triageNote
        )
        let forecast = try await session.respond(to: user, generating: Forecast.self).content

        return RiskSnapshot(
            riskLevel: RiskLevel(rawValue: forecast.riskLevel.lowercased()) ?? .guarded,
            score: Double(forecast.score),
            windowHours: forecast.windowHours,
            drivers: forecast.drivers.map {
                RiskDriver(
                    factor: $0.factor,
                    detail: $0.detail,
                    direction: RiskDriver.Direction(rawValue: $0.direction.lowercased()) ?? .steady,
                    impact: $0.impact
                )
            },
            explanation: forecast.explanation,
            actions: forecast.actions
        )
    }

    private static var apiKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
        guard let key, !key.isEmpty, key != "sk-ant-REPLACE_ME" else { return nil }
        return key
    }
}
