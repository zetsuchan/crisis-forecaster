import Foundation

/// Calibrated risk bands. Tone matters: these are companion-grade words,
/// not clinical alarms (see founder design principles).
enum RiskLevel: String, Codable, Sendable, CaseIterable {
    case low
    case guarded
    case elevated
    case high

    var title: String {
        switch self {
        case .low: "Low"
        case .guarded: "Guarded"
        case .elevated: "Elevated"
        case .high: "High"
        }
    }

    /// Plain-language one-liner used in Siri dialog and the dashboard ring.
    var headline: String {
        switch self {
        case .low: "Things look steady."
        case .guarded: "Worth keeping an eye on."
        case .elevated: "Your body is trending toward a crisis window."
        case .high: "Several triggers are stacking up — act now."
        }
    }

    /// Does this band warrant staging the Emergency Passport?
    var isElevated: Bool { self == .elevated || self == .high }
}

/// The full daily forecast Claude produces. The wire format (from Claude's
/// structured output) contains only the snake_case fields; `id`/`generatedAt`
/// are added locally and round-trip through SharedStore via decodeIfPresent.
struct RiskSnapshot: Codable, Sendable, Identifiable {
    var id: UUID
    var riskLevel: RiskLevel
    /// 0–100 (validated client-side; the API schema can't express numeric bounds).
    var score: Double
    var windowHours: Int
    var drivers: [RiskDriver]
    /// The "why", in plain language. The product's headline feature.
    var explanation: String
    var actions: [String]
    var generatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case riskLevel = "risk_level"
        case score
        case windowHours = "window_hours"
        case drivers
        case explanation
        case actions
        case generatedAt = "generated_at"
    }

    init(
        riskLevel: RiskLevel,
        score: Double,
        windowHours: Int,
        drivers: [RiskDriver],
        explanation: String,
        actions: [String],
        id: UUID = UUID(),
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.riskLevel = riskLevel
        self.score = score.clamped(to: 0...100)
        self.windowHours = windowHours
        self.drivers = drivers
        self.explanation = explanation
        self.actions = actions
        self.generatedAt = generatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        riskLevel = try c.decode(RiskLevel.self, forKey: .riskLevel)
        // Models sometimes return score on a 0–1 scale; normalize to 0–100.
        var rawScore = try c.decode(Double.self, forKey: .score)
        if rawScore > 0, rawScore <= 1 { rawScore *= 100 }
        score = rawScore.clamped(to: 0...100)
        windowHours = try c.decode(Int.self, forKey: .windowHours)
        drivers = try c.decode([RiskDriver].self, forKey: .drivers)
        explanation = try c.decode(String.self, forKey: .explanation)
        actions = try c.decode([String].self, forKey: .actions)
        // Present only when reloaded from SharedStore; absent in Claude's response.
        id = (try c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        generatedAt = (try c.decodeIfPresent(Date.self, forKey: .generatedAt)) ?? Date()
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
