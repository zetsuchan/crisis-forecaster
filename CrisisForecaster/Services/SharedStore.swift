import Foundation

/// Single source of truth for the latest forecast + passport, written to the
/// App Group container so the App Intents (Siri) can read them with the app closed.
///
/// JSON files in the shared container are used rather than UserDefaults so the
/// payloads can grow (passport markdown) without bumping into defaults limits.
struct SharedStore: Sendable {
    static let appGroupID = "group.com.crisisforecaster.app"

    enum StoreError: Error { case appGroupUnavailable }

    /// Prefer the App Group container (so out-of-process Siri intents can read it).
    /// Fall back to the app's own Application Support dir when the group isn't
    /// provisioned (e.g. unsigned simulator builds) so in-app persistence still works.
    private var containerURL: URL? {
        let fm = FileManager.default
        if let group = fm.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return group
        }
        return try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    private func url(for name: String) -> URL? {
        containerURL?.appendingPathComponent(name, conformingTo: .json)
    }

    // MARK: Risk

    func saveRisk(_ snapshot: RiskSnapshot) throws {
        try write(snapshot, to: "risk_snapshot")
    }

    func loadRisk() -> RiskSnapshot? {
        read("risk_snapshot")
    }

    // MARK: Passport

    func savePassport(_ passport: EmergencyPassport) throws {
        try write(passport, to: "emergency_passport")
    }

    func loadPassport() -> EmergencyPassport? {
        read("emergency_passport")
    }

    // MARK: Profile

    func saveProfile(_ profile: PatientProfile) throws {
        try write(profile, to: "patient_profile")
    }

    func loadProfile() -> PatientProfile? {
        read("patient_profile")
    }

    // MARK: IO

    private func write<T: Encodable>(_ value: T, to name: String) throws {
        guard let url = url(for: name) else { throw StoreError.appGroupUnavailable }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    private func read<T: Decodable>(_ name: String) -> T? {
        guard let url = url(for: name), let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
}
