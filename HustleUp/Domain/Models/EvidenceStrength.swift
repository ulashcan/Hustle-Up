import Foundation

enum EvidenceStrength: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case strongSignal = "STRONG SIGNAL"
    case likely = "LIKELY"
    case possible = "POSSIBLE"
    case unknown = "UNKNOWN"

    static func resolve(
        needsMoreContext: Bool,
        usedFallbackMove: Bool,
        confidence: Double
    ) -> EvidenceStrength {
        if needsMoreContext { return .unknown }
        if usedFallbackMove { return .possible }
        if confidence >= 0.8 { return .strongSignal }
        if confidence >= 0.55 { return .likely }
        if confidence >= 0.35 { return .possible }
        return .unknown
    }
}
