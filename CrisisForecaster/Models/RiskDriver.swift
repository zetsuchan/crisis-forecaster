import Foundation

/// One contributing signal in the forecast, e.g. "Barometric pressure",
/// "dropping 15mb overnight", direction .down.
struct RiskDriver: Codable, Sendable, Identifiable, Hashable {
    var id: UUID = UUID()
    var factor: String
    var detail: String
    var direction: Direction

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
        case factor, detail, direction
    }

    init(factor: String, detail: String, direction: Direction) {
        self.factor = factor
        self.detail = detail
        self.direction = direction
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        factor = try c.decode(String.self, forKey: .factor)
        detail = try c.decode(String.self, forKey: .detail)
        direction = try c.decode(Direction.self, forKey: .direction)
        id = UUID()
    }
}
