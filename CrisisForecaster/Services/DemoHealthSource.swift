import Foundation

/// Replays a scripted 14-day "crisis-building" decline from a bundled JSON file
/// so the stage demo is deterministic and never depends on real device history.
/// The dates in the file are relative offsets; we anchor them to "today" at load.
struct DemoHealthSource: HealthDataSource {

    struct DemoDay: Decodable {
        let dayOffset: Int          // 0 = oldest, 13 = today
        let restingHeartRate: Double?
        let hrv: Double?
        let spo2: Double?
        let sleepHours: Double?
        let sleepFragmentation: Double?
    }

    func recentVitals(days: Int) async throws -> [VitalsSnapshot] {
        let all = try Self.loadAll()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let maxOffset = all.map(\.dayOffset).max() ?? 0

        let snapshots = all.map { day -> VitalsSnapshot in
            // Map dayOffset so the highest offset lands on today.
            let daysAgo = maxOffset - day.dayOffset
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return VitalsSnapshot(
                date: date,
                restingHeartRate: day.restingHeartRate,
                hrv: day.hrv,
                spo2: day.spo2,
                sleepHours: day.sleepHours,
                sleepFragmentation: day.sleepFragmentation
            )
        }
        .sorted { $0.date < $1.date }

        return Array(snapshots.suffix(days))
    }

    static func loadAll() throws -> [DemoDay] {
        guard let url = Bundle.main.url(forResource: "demo_decline_14d", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([DemoDay].self, from: data)
    }
}
