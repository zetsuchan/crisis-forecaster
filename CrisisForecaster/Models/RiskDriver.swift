import Foundation

/// One contributing signal in the forecast, e.g. "Barometric pressure",
/// "dropping 15mb overnight", direction .down.
struct RiskDriver: Codable, Sendable, Identifiable, Hashable {
    var id: UUID = UUID()
    var factor: String
    var detail: String
    var direction: Direction
    /// One grounded sentence: why this signal matters for THIS patient. Shown on tap.
    var impact: String

    enum Direction: String, Codable, Sendable {
        case up
        case down
        case steady

        var symbol: String {
            switch self {
            case .up: "arrow.up.right"
            case .down: "arrow.down.right"
            case .steady: "arrow.right"
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case factor, detail, direction, impact
    }

    init(factor: String, detail: String, direction: Direction, impact: String = "") {
        self.factor = factor
        self.detail = detail
        self.direction = direction
        self.impact = impact
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        factor = try c.decode(String.self, forKey: .factor)
        detail = try c.decode(String.self, forKey: .detail)
        direction = try c.decode(Direction.self, forKey: .direction)
        impact = (try c.decodeIfPresent(String.self, forKey: .impact)) ?? ""
        id = UUID()
    }
}
