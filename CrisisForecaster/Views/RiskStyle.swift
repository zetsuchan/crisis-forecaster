import SwiftUI

/// Shared visual mapping for risk bands. Calm palette — companion, not alarm.
enum RiskStyle {
    static func color(_ level: RiskLevel) -> Color {
        switch level {
        case .low: .green
        case .guarded: .yellow
        case .elevated: .orange
        case .high: .red
        }
    }

    static func icon(_ level: RiskLevel) -> String {
        switch level {
        case .low: "checkmark.circle.fill"
        case .guarded: "eye.circle.fill"
        case .elevated: "exclamationmark.triangle.fill"
        case .high: "bolt.heart.fill"
        }
    }
}
