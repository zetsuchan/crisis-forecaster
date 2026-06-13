import Foundation

/// The patient's own report of how they feel — "learn YOUR language for your body."
/// Closes the loop: the latest check-in folds into Claude's next forecast and the
/// Emergency Passport.
struct CheckIn: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    /// 0 (none) – 10 (worst).
    var painLevel: Int
    var painLocations: [String]
    var hydration: Hydration
    var notes: String

    enum Hydration: String, Codable, Sendable, CaseIterable {
        case low, ok, good
        var label: String {
            switch self {
            case .low: "Low"
            case .ok: "OK"
            case .good: "Good"
            }
        }
    }

    /// Candidate body locations for the picker.
    static let bodyLocations = ["Back", "Legs", "Arms", "Chest", "Abdomen", "Joints", "Head"]

    init(
        painLevel: Int = 0,
        painLocations: [String] = [],
        hydration: Hydration = .ok,
        notes: String = "",
        id: UUID = UUID(),
        date: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.painLevel = painLevel
        self.painLocations = painLocations
        self.hydration = hydration
        self.notes = notes
    }

    /// One-line form folded into Claude prompts.
    var promptLine: String {
        var parts = ["pain \(painLevel)/10"]
        if !painLocations.isEmpty { parts.append("in \(painLocations.joined(separator: ", "))") }
        parts.append("hydration \(hydration.label.lowercased())")
        if !notes.isEmpty { parts.append("notes: \(notes)") }
        return parts.joined(separator: ", ")
    }
}
