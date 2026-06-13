import Foundation
import FoundationModels

/// On-device triage using Apple's Foundation Models (iOS 27 `SystemLanguageModel`).
///
/// The dual-model architecture: this private, instant, offline model is the
/// "triage nurse" — it reads the patient's self-report, normalizes it into a clean
/// clinical line, judges concern, and decides whether to escalate to the frontier
/// "specialist" (Claude Opus 4.8) for the full crisis forecast.
///
/// Availability-gated: on a device/sim without Apple Intelligence it falls back to a
/// transparent heuristic so the app still works (per "app-side demo primary").
struct OnDeviceTriage: Sendable {
    func assess(checkIn: CheckIn, profile: PatientProfile) async -> TriageResult {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return heuristic(checkIn)
        }

        let instructions = """
        You are an on-device triage aide for a person with sickle cell disease. \
        Summarize their self-report in one crisp clinical sentence for a clinician, \
        judge how concerning it is, and decide whether it warrants re-running the \
        full crisis forecast now. Be factual. Do not give medical advice.
        """
        let baseSpO2 = profile.baselineSpO2.map { "\(Int($0 * 100))%" } ?? "unknown"
        let prompt = """
        Patient self-report: \(checkIn.promptLine).
        Variant: \(profile.variant). Baseline SpO2: \(baseSpO2).
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: CheckInTriage.self)
            let t = response.content
            return TriageResult(
                summary: t.summary,
                concern: min(max(t.concern, 0), 10),
                escalate: t.escalate,
                source: .appleOnDevice
            )
        } catch {
            return heuristic(checkIn)
        }
    }

    /// Transparent fallback when the on-device model isn't available.
    private func heuristic(_ c: CheckIn) -> TriageResult {
        let escalate = c.painLevel >= 6 || c.hydration == .low
        return TriageResult(
            summary: "Self-reported \(c.promptLine).",
            concern: c.painLevel,
            escalate: escalate,
            source: .heuristic
        )
    }
}

/// Result of on-device triage, surfaced in the UI to show the dual-model flow.
struct TriageResult: Sendable, Codable {
    enum Source: String, Sendable, Codable {
        case appleOnDevice
        case heuristic

        var label: String {
            switch self {
            case .appleOnDevice: "Apple Intelligence · on-device"
            case .heuristic: "On-device rules"
            }
        }
    }

    var summary: String
    /// 0–10
    var concern: Int
    var escalate: Bool
    var source: Source
}

/// Guided-generation schema for the on-device model.
@Generable
struct CheckInTriage {
    @Guide(description: "One clear clinical sentence summarizing the patient's self-report for a clinician.")
    var summary: String
    @Guide(description: "Concern level from 0 (fine) to 10 (urgent), as a whole number.")
    var concern: Int
    @Guide(description: "True if this self-report warrants re-running the full crisis forecast now.")
    var escalate: Bool
}
