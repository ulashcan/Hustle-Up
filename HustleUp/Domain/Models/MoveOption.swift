import Foundation

struct MoveOption: Codable, Sendable, Equatable, Hashable, Identifiable {
    var move: MoveVerb
    var purpose: String
    var risk: String
    var upside: String
    var execution: String
    var isRecommended: Bool

    var id: String { move.rawValue }
}
