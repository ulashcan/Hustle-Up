import Foundation

enum AnalyticsEvent: String, Sendable, Equatable {
    case appOpen = "app_open"
    case screenshotSelected = "screenshot_selected"
    case analysisStarted = "analysis_started"
    case analysisCompleted = "analysis_completed"
    case analysisFailed = "analysis_failed"
    case moveViewed = "move_viewed"
    case fumbleCheckStarted = "fumble_check_started"
    case fumbleDetected = "fumble_detected"
    case practiceStarted = "practice_started"
    case practiceCompleted = "practice_completed"
    case outcomeRecorded = "outcome_recorded"
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
}

struct AnalyticsParameters: Sendable, Equatable {
    var source: String?
    var category: String?
    var move: String?
    var verdict: String?
    var failure: String?
    var feature: String?
    var outcome: String?

    static func source(_ source: InputSource) -> AnalyticsParameters {
        AnalyticsParameters(source: source.rawValue)
    }

    static func failure(_ error: AppError) -> AnalyticsParameters {
        AnalyticsParameters(failure: error.analyticsCode)
    }

    static func analysis(_ analysis: SituationAnalysis) -> AnalyticsParameters {
        AnalyticsParameters(category: analysis.category.rawValue, move: analysis.move.rawValue)
    }

    static func fumble(_ result: FumbleCheckResult) -> AnalyticsParameters {
        AnalyticsParameters(verdict: result.verdict.rawValue)
    }

    static func feature(_ feature: Feature) -> AnalyticsParameters {
        AnalyticsParameters(feature: feature.rawValue)
    }

    static func outcome(_ result: MoveOutcome, move: MoveVerb) -> AnalyticsParameters {
        AnalyticsParameters(move: move.rawValue, outcome: result.rawValue)
    }

    static let empty = AnalyticsParameters()
}

protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent, parameters: AnalyticsParameters)
}

struct InMemoryAnalytics: AnalyticsTracking {
    struct Record: Sendable, Equatable {
        var event: AnalyticsEvent
        var parameters: AnalyticsParameters
    }

    private let storage: Storage

    init(storage: Storage = Storage()) {
        self.storage = storage
    }

    func track(_ event: AnalyticsEvent, parameters: AnalyticsParameters) {
        storage.append(Record(event: event, parameters: parameters))
    }

    @MainActor
    var records: [Record] { storage.records }

    final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var _records: [Record] = []

        var records: [Record] {
            lock.lock()
            defer { lock.unlock() }
            return _records
        }

        func append(_ record: Record) {
            lock.lock()
            _records.append(record)
            lock.unlock()
        }
    }
}

enum HULog {
    static func debug(_ message: StaticString) {
        #if DEBUG
        print("[HUSTLEUP] \(message)")
        #endif
    }
}
