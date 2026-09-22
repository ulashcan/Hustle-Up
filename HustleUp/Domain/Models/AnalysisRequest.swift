import Foundation

enum InputSource: String, Codable, Sendable, Equatable, Hashable {
    case screenshot
    case typed
    case example
}

struct AnalysisRequest: Codable, Sendable, Equatable, Hashable {
    var source: InputSource
    var text: String
    var ocrConfidence: Double?
    var wasTruncated: Bool

    init(
        source: InputSource,
        text: String,
        ocrConfidence: Double? = nil,
        wasTruncated: Bool = false
    ) {
        self.source = source
        self.text = text
        self.ocrConfidence = ocrConfidence
        self.wasTruncated = wasTruncated
    }
}

struct StoredAnalysis: Codable, Sendable, Equatable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let request: AnalysisRequest
    let analysis: SituationAnalysis
    var outcome: MoveOutcomeRecord?

    init(
        id: UUID,
        createdAt: Date,
        request: AnalysisRequest,
        analysis: SituationAnalysis,
        outcome: MoveOutcomeRecord? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.request = request
        self.analysis = analysis
        self.outcome = outcome
    }
}
