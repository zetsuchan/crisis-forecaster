import Foundation

/// Asks Claude to score VOC risk 24–72h out from already-gathered vitals + weather,
/// and returns a structured RiskSnapshot. This is where "Claude does the reasoning."
/// AppModel owns data gathering so the same vitals can feed the trend view.
struct RiskEngine: Sendable {
    let claude: ClaudeClient

    func score(
        profile: PatientProfile,
        vitals: [VitalsSnapshot],
        weather: WeatherSnapshot,
        checkIn: CheckIn? = nil,
        triageNote: String? = nil
    ) async throws -> RiskSnapshot {
        let user = Self.buildUserMessage(vitals: vitals, weather: weather, profile: profile, checkIn: checkIn, triageNote: triageNote)
        return try await claude.completeJSON(
            system: Self.systemPrompt,
            user: user,
            jsonSchema: Self.riskSchema,
            maxTokens: 1500,
            as: RiskSnapshot.self
        )
    }

    // MARK: Prompt

    /// Encodes the trigger chain and the founder's emotional-design rules:
    /// companion not monitor, no alarmism, respect patient expertise.
    static let systemPrompt = """
    You are the reasoning core of Crisis Forecaster, an early-warning companion for a \
    person living with sickle cell disease. You estimate the risk of a vaso-occlusive \
    crisis (VOC) in the next 24–72 hours from their recent vitals and local weather.

    Known VOC trigger signals (consider trends, not just absolute values):
    - Rising resting heart rate vs the person's baseline.
    - Falling heart-rate variability (HRV).
    - Dips in blood oxygen saturation (SpO2), especially below ~0.94.
    - Sleep loss and rising sleep fragmentation.
    - Barometric pressure DROPS (incoming cold fronts) and LOW humidity.
    - Cold temperature.
    Triggers stack: several mild shifts together matter more than one alone.

    How to communicate (this person has spent a lifetime managing this disease):
    - Be a trusted companion, not a clinical monitor. Warm, plain language.
    - Never be alarmist; never catastrophize. They already live with the fear.
    - Respect their expertise — explain the WHY so they can act, don't lecture.
    - The explanation is the product. Name the specific signals you saw, like:
      "pressure is dropping 15mb tonight, your sleep has been fragmenting, and your \
      resting heart rate is up 8 bpm from baseline — hydrate aggressively and \
      pre-position your pain plan."
    - Actions should be concrete and self-management oriented (hydration, warmth, \
      rest, pacing, readying the pain plan), and mention staging for the ER only at \
      genuinely high risk.

    Return ONLY the structured object.
    - score is an integer from 0 to 100 (NOT a 0–1 fraction). Higher = more risk.
    - Pick the risk_level band that matches the score and the trigger picture.
    - For each driver, `direction` describes how that METRIC moved, not the risk: \
      use "down" when the value fell (e.g. SpO2 0.98→0.93 is "down", HRV falling is \
      "down"), "up" when it rose (resting HR rising is "up"), "steady" otherwise.
    """

    static func buildUserMessage(
        vitals: [VitalsSnapshot],
        weather: WeatherSnapshot,
        profile: PatientProfile,
        checkIn: CheckIn? = nil,
        triageNote: String? = nil
    ) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        func encode<T: Encodable>(_ value: T) -> String {
            (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        }

        return """
        Patient context:
        - Variant: \(profile.variant)
        - Baseline resting HR: \(profile.baselineRestingHR.map { String(format: "%.0f bpm", $0) } ?? "unknown")
        - Baseline SpO2: \(profile.baselineSpO2.map { String(format: "%.0f%%", $0 * 100) } ?? "unknown")

        Last 14 days of vitals (oldest first), JSON:
        \(encode(vitals))

        Current / incoming local weather, JSON:
        \(encode(weather))
        \(selfReportLine(checkIn: checkIn, triageNote: triageNote))
        Score the VOC crisis risk for the next 24–72 hours and explain why.
        """
    }

    /// Prefer the on-device triage digest (Apple Intelligence) when present;
    /// otherwise fall back to the raw check-in line.
    private static func selfReportLine(checkIn: CheckIn?, triageNote: String?) -> String {
        if let triageNote {
            return "\nOn-device triage of the patient's check-in (Apple Intelligence): \(triageNote) Weigh this self-report heavily."
        }
        if let checkIn {
            return "\nThe patient's own check-in today: \(checkIn.promptLine). Weigh this self-report heavily."
        }
        return ""
    }

    // MARK: Structured-output schema (mirrors RiskSnapshot wire format)

    static var riskSchema: [String: Any] {[
        "type": "object",
        "additionalProperties": false,
        "required": ["risk_level", "score", "window_hours", "drivers", "explanation", "actions"],
        "properties": [
            "risk_level": ["type": "string", "enum": ["low", "guarded", "elevated", "high"]],
            "score": ["type": "number", "description": "Risk score from 0 to 100 (whole number, e.g. 78 — NOT a 0-1 fraction)."],
            "window_hours": ["type": "integer", "description": "Forecast horizon, 24 to 72."],
            "drivers": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["factor", "detail", "direction"],
                    "properties": [
                        "factor": ["type": "string"],
                        "detail": ["type": "string"],
                        "direction": ["type": "string", "enum": ["up", "down", "steady"], "description": "How the metric itself moved, not the risk."],
                    ],
                ],
            ],
            "explanation": ["type": "string"],
            "actions": ["type": "array", "items": ["type": "string"]],
        ],
    ]}
}
