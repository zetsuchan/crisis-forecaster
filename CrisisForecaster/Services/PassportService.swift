import Foundation

/// On elevated risk, drafts the Emergency Passport — the ER handoff packet — so
/// the handoff is already done if a visit happens. "The Passport is the moat."
///
/// Claude produces only the parts that need judgement (a triage summary and the
/// critical flags); the rest of the packet renders from the patient profile.
struct PassportService: Sendable {
    let claude: ClaudeClient

    /// Claude's structured contribution.
    private struct Brief: Decodable {
        let triage_summary: String
        let critical_flags: [String]
    }

    static let systemPrompt = """
    You prepare two fields for a sickle cell Emergency Department handoff. A triage \
    nurse reads this in seconds. Be factual; never invent clinical details beyond \
    what's provided.

    triage_summary: EXACTLY 1–2 complete sentences. State the diagnosis, why they're \
    here now, and the single most important thing to act on. Do NOT include lists, \
    bullets, the word "Note", the flags themselves, or any commentary about \
    formatting or the schema.

    critical_flags: 2–5 SHORT flags, a few words each, each as its own array item. \
    Allergies, high-risk history, and danger-zone vitals go HERE, not in the summary.

    Example of the SHAPE only (do not reuse this content — use the patient's real data):
    triage_summary: "HbSC patient in a guarded vaso-occlusive window with worsening \
    leg pain. Prioritize early analgesia and check for dehydration."
    critical_flags: ["Penicillin allergy", "Prior acute chest syndrome", \
    "On crizanlizumab", "Baseline SpO2 95%"]

    Return ONLY the structured object.
    """

    private static var schema: [String: Any] {[
        "type": "object",
        "additionalProperties": false,
        "required": ["triage_summary", "critical_flags"],
        "properties": [
            "triage_summary": ["type": "string"],
            "critical_flags": ["type": "array", "items": ["type": "string"]],
        ],
    ]}

    func draft(profile: PatientProfile, risk: RiskSnapshot, checkIn: CheckIn? = nil) async throws -> EmergencyPassport {
        let riskContext = "\(risk.riskLevel.title) risk (\(Int(risk.score))/100), \(risk.windowHours)h window"
        let user = """
        Patient: \(profile.fullName)
        Variant: \(profile.variant)
        Baseline resting HR: \(profile.baselineRestingHR.map { String(format: "%.0f bpm", $0) } ?? "unknown")
        Baseline SpO2: \(profile.baselineSpO2.map { String(format: "%.0f%%", $0 * 100) } ?? "unknown")
        Medications: \(profile.medications.joined(separator: "; "))
        Allergies: \(profile.allergies.joined(separator: "; "))
        Pain plan: \(profile.painPlan)
        Notes: \(profile.notes)
        \(checkIn.map { "Patient's current self-report: \($0.promptLine)" } ?? "")

        Current risk context: \(riskContext). \(risk.explanation)
        """
        let brief = try await claude.completeJSON(
            system: Self.systemPrompt,
            user: user,
            jsonSchema: Self.schema,
            maxTokens: 600,
            as: Brief.self
        )
        return EmergencyPassport(
            triageSummary: brief.triage_summary,
            criticalFlags: brief.critical_flags,
            profile: profile,
            riskContext: riskContext
        )
    }
}
