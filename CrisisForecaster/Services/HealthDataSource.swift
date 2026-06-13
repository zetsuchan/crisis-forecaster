import Foundation

/// The seam that lets the whole app be source-agnostic. Demo Mode and Live Mode
/// both conform; the Settings toggle picks one. The 14-day history is what the
/// RiskEngine feeds Claude to reason about trends, not just today's numbers.
protocol HealthDataSource: Sendable {
    /// Most recent first is NOT required; RiskEngine sorts by date.
    func recentVitals(days: Int) async throws -> [VitalsSnapshot]
}

extension HealthDataSource {
    func currentVitals() async throws -> VitalsSnapshot? {
        try await recentVitals(days: 1).max(by: { $0.date < $1.date })
    }
}
