import Foundation

/// Entered once during onboarding; the raw material for the Emergency Passport.
/// Kept on-device. Never log secrets or PII to the console.
struct PatientProfile: Codable, Sendable {
    var fullName: String
    /// e.g. "HbSS", "HbSC", "HbS beta-thalassemia"
    var variant: String
    var baselineRestingHR: Double?
    var baselineSpO2: Double?
    /// Free-text current medications (hydroxyurea, voxelotor, crizanlizumab, folic acid…)
    var medications: [String]
    /// The patient's own pain plan — what works for them.
    var painPlan: String
    var allergies: [String]
    var hematologistName: String
    var hematologistPhone: String
    var emergencyContactName: String
    var emergencyContactPhone: String
    var notes: String

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? ""
    }

    /// Starting point for a real user's onboarding: blank identity, but baseline
    /// vitals pre-filled from the user's own Apple Watch history (resting HR 55,
    /// SpO2 ~97%) so the Passport is grounded without making them look those up.
    static let recordingStarter = PatientProfile(
        fullName: "",
        variant: "HbSS",
        baselineRestingHR: 55,
        baselineSpO2: 0.97,
        medications: [],
        painPlan: "",
        allergies: [],
        hematologistName: "",
        hematologistPhone: "",
        emergencyContactName: "",
        emergencyContactPhone: "",
        notes: ""
    )

    static let empty = PatientProfile(
        fullName: "",
        variant: "HbSS",
        baselineRestingHR: nil,
        baselineSpO2: nil,
        medications: [],
        painPlan: "",
        allergies: [],
        hematologistName: "",
        hematologistPhone: "",
        emergencyContactName: "",
        emergencyContactPhone: "",
        notes: ""
    )

    /// Demo profile so the stage demo shows a fully-formed passport without onboarding.
    static let demo = PatientProfile(
        fullName: "Jordan Ade",
        variant: "HbSS (with elevated HbF)",
        baselineRestingHR: 62,
        baselineSpO2: 0.97,
        medications: ["Hydroxyurea 1500mg daily", "Folic acid 5mg daily"],
        painPlan: "Home: aggressive oral hydration, heat, stretching, calm. Escalate to oral opioids per plan. ER trigger: pain unrelieved after 2h or SpO2 < 92%.",
        allergies: ["Codeine"],
        hematologistName: "Dr. Imani Okafor",
        hematologistPhone: "+1 (555) 012-3456",
        emergencyContactName: "Sam Ade",
        emergencyContactPhone: "+1 (555) 098-7654",
        notes: "High fetal hemoglobin — historically reduces crisis severity. Prior splenic sequestration as a child."
    )
}
