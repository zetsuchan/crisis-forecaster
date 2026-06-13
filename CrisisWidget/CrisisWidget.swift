import WidgetKit
import SwiftUI

/// Reads the latest forecast from the shared App Group and shows it on the Home
/// Screen and Lock Screen — reinforcing the "ambient, never open the app" pitch.
/// Lock-screen accessory families let Siri's warning live where the patient sees it.
struct RiskEntry: TimelineEntry {
    let date: Date
    let risk: RiskSnapshot?
}

struct RiskProvider: TimelineProvider {
    func placeholder(in context: Context) -> RiskEntry {
        RiskEntry(date: Date(), risk: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RiskEntry) -> Void) {
        completion(RiskEntry(date: Date(), risk: SharedStore().loadRisk()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RiskEntry>) -> Void) {
        let entry = RiskEntry(date: Date(), risk: SharedStore().loadRisk())
        // Re-read hourly; the app/background task writes fresh forecasts.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct CrisisWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RiskEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        default: small
        }
    }

    // Home Screen (systemSmall)
    private var small: some View {
        VStack(spacing: 6) {
            if let risk = entry.risk {
                Image(systemName: RiskStyle.icon(risk.riskLevel))
                    .font(.title2)
                    .foregroundStyle(RiskStyle.color(risk.riskLevel))
                Text(risk.riskLevel.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("\(Int(risk.score)) / 100")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Crisis risk · \(risk.windowHours)h")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Image(systemName: "waveform.path.ecg").font(.title2).foregroundStyle(.secondary)
                Text("No forecast yet").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if let risk = entry.risk {
                RiskStyle.color(risk.riskLevel).opacity(0.12)
            } else {
                Color.clear
            }
        }
    }

    // Lock Screen rectangular
    private var rectangular: some View {
        HStack(spacing: 8) {
            if let risk = entry.risk {
                Image(systemName: RiskStyle.icon(risk.riskLevel))
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text("Crisis risk · \(risk.riskLevel.title)")
                        .font(.headline)
                        .widgetAccentable()
                    Text("\(Int(risk.score))/100 · next \(risk.windowHours)h")
                        .font(.caption)
                }
            } else {
                Image(systemName: "waveform.path.ecg")
                Text("No forecast yet").font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    // Lock Screen circular gauge
    private var circular: some View {
        Gauge(value: entry.risk.map { $0.score / 100 } ?? 0) {
            Image(systemName: "drop.fill")
        } currentValueLabel: {
            Text(entry.risk.map { "\(Int($0.score))" } ?? "—")
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) { Color.clear }
    }

    // Lock Screen inline
    private var inline: some View {
        Label(
            entry.risk.map { "Crisis risk: \($0.riskLevel.title)" } ?? "Crisis risk: —",
            systemImage: "waveform.path.ecg"
        )
    }
}

struct CrisisWidget: Widget {
    let kind = "CrisisWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RiskProvider()) { entry in
            CrisisWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Crisis Risk")
        .description("Your latest vaso-occlusive crisis risk, on the Home and Lock Screen.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct CrisisWidgetBundle: WidgetBundle {
    var body: some Widget {
        CrisisWidget()
    }
}
