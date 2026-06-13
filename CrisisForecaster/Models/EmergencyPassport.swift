import Foundation

/// The ER handoff packet — staged before the visit happens. "The Passport is the moat."
///
/// Structured rather than a markdown blob: Claude writes the triage summary and
/// picks the critical flags; the rest renders natively from a snapshot of the
/// patient profile so the view is clean, scannable, and offline.
struct EmergencyPassport: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    /// Claude-written, 1–2 sentences for the triage nurse.
    var triageSummary: String
    /// Claude-picked, the few things that change immediate management.
    var criticalFlags: [String]
    /// Self-contained snapshot so the passport stands alone.
    var profile: PatientProfile
    /// Why this packet exists right now (risk context at staging time).
    var riskContext: String
    var generatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey {
        case id, triageSummary, criticalFlags, profile, riskContext, generatedAt
    }

    init(
        triageSummary: String,
        criticalFlags: [String],
        profile: PatientProfile,
        riskContext: String,
        id: UUID = UUID(),
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.triageSummary = triageSummary
        self.criticalFlags = criticalFlags
        self.profile = profile
        self.riskContext = riskContext
        self.generatedAt = generatedAt
    }

    /// Plain-text packet for ShareLink / handing to staff who want a copy.
    var shareText: String {
        var lines: [String] = ["SICKLE CELL EMERGENCY PASSPORT", ""]
        lines.append("\(profile.fullName) — \(profile.variant)")
        if !criticalFlags.isEmpty {
            lines.append("")
            lines.append("CRITICAL: " + criticalFlags.joined(separator: " · "))
        }
        lines.append("")
        lines.append("TRIAGE: \(triageSummary)")
        lines.append("")
        if let hr = profile.baselineRestingHR { lines.append("Baseline resting HR: \(Int(hr)) bpm") }
        if let spo2 = profile.baselineSpO2 { lines.append("Baseline SpO2: \(Int(spo2 * 100))%") }
        if !profile.medications.isEmpty {
            lines.append("")
            lines.append("Medications: " + profile.medications.joined(separator: "; "))
        }
        if !profile.allergies.isEmpty {
            lines.append("Allergies: " + profile.allergies.joined(separator: "; "))
        }
        if !profile.painPlan.isEmpty {
            lines.append("")
            lines.append("Pain plan: \(profile.painPlan)")
        }
        lines.append("")
        lines.append("Hematologist: \(profile.hematologistName) \(profile.hematologistPhone)")
        lines.append("Emergency contact: \(profile.emergencyContactName) \(profile.emergencyContactPhone)")
        lines.append("")
        lines.append("Context: \(riskContext)")
        return lines.joined(separator: "\n")
    }
}
