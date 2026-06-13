import Foundation

/// A single day's vitals. The 14-day series of these is what we hand Claude.
struct VitalsSnapshot: Codable, Sendable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    /// bpm
    var restingHeartRate: Double?
    /// ms (SDNN); lower trend can precede a crisis
    var hrv: Double?
    /// blood oxygen fraction 0–1 (e.g. 0.96)
    var spo2: Double?
    var sleepHours: Double?
    /// 0–1, share of the night spent awake/restless
    var sleepFragmentation: Double?

    init(
        date: Date,
        restingHeartRate: Double? = nil,
        hrv: Double? = nil,
        spo2: Double? = nil,
        sleepHours: Double? = nil,
        sleepFragmentation: Double? = nil
    ) {
        self.date = date
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.spo2 = spo2
        self.sleepHours = sleepHours
        self.sleepFragmentation = sleepFragmentation
    }
}
