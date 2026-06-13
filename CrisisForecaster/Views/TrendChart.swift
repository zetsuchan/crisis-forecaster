import SwiftUI
import Charts

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Compact sparkline of one vital over the 14-day window, with a delta readout,
/// so the forecast visibly comes from the body's trend.
struct TrendRow: View {
    let title: String
    let unit: String
    let points: [TrendPoint]
    /// true if a rising value is concerning (e.g. resting HR); flips the delta color.
    let riseIsBad: Bool

    private var delta: Double? {
        guard let first = points.first?.value, let last = points.last?.value else { return nil }
        return last - first
    }

    private var deltaColor: Color {
        guard let delta else { return .secondary }
        if abs(delta) < 0.0001 { return .secondary }
        let bad = riseIsBad ? delta > 0 : delta < 0
        return bad ? .orange : .green
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                if let delta {
                    Text(deltaText(delta))
                        .font(.caption)
                        .foregroundStyle(deltaColor)
                }
            }
            .frame(width: 104, alignment: .leading)

            Chart(points) { point in
                LineMark(x: .value("Day", point.date), y: .value(title, point.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(deltaColor)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 40)
        }
    }

    private func deltaText(_ delta: Double) -> String {
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(format(delta)) \(unit) / 14d"
    }

    private func format(_ v: Double) -> String {
        abs(v) < 1 ? String(format: "%.2f", v) : String(format: "%.0f", v)
    }
}

/// The set of trend rows derived from the stored vitals series.
struct TrendsSection: View {
    let vitals: [VitalsSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your last 14 days")
                .font(.headline)
            TrendRow(title: "Resting HR", unit: "bpm", points: series { $0.restingHeartRate }, riseIsBad: true)
            TrendRow(title: "HRV", unit: "ms", points: series { $0.hrv }, riseIsBad: false)
            TrendRow(title: "Blood oxygen", unit: "", points: series { $0.spo2 }, riseIsBad: false)
            TrendRow(title: "Sleep", unit: "h", points: series { $0.sleepHours }, riseIsBad: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func series(_ key: (VitalsSnapshot) -> Double?) -> [TrendPoint] {
        vitals.compactMap { v in key(v).map { TrendPoint(date: v.date, value: $0) } }
    }
}
