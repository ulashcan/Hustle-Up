import Foundation

@MainActor
protocol EntitlementProviding: AnyObject {
    var isPro: Bool { get }
    var remainingFreeAnalyses: Int { get }
    var analysesUsed: Int { get }
    func canUse(_ feature: Feature) -> Bool
    func consumeAnalysis() throws(AppError)
    func setProPreview(_ enabled: Bool)
    func resetAll()
}

@Observable
@MainActor
final class EntitlementStore: EntitlementProviding {
    static let freeAnalysisLimit = 3

    private let defaults: UserDefaults
    private let proKey: String
    private let usedKey: String

    var isPro: Bool {
        didSet { defaults.set(isPro, forKey: proKey) }
    }

    private(set) var analysesUsed: Int {
        didSet { defaults.set(analysesUsed, forKey: usedKey) }
    }

    init(
        defaults: UserDefaults = .standard,
        proKey: String = "hu.isProPreview",
        usedKey: String = "hu.analysesUsed"
    ) {
        self.defaults = defaults
        self.proKey = proKey
        self.usedKey = usedKey
        self.isPro = defaults.bool(forKey: proKey)
        self.analysesUsed = defaults.integer(forKey: usedKey)
    }

    var remainingFreeAnalyses: Int {
        if isPro { return Int.max }
        return max(0, Self.freeAnalysisLimit - analysesUsed)
    }

    func canUse(_ feature: Feature) -> Bool {
        switch feature {
        case .analysis:
            return isPro || analysesUsed < Self.freeAnalysisLimit
        case .fumbleCheck, .practice, .history, .advancedAnalysis:
            return isPro
        }
    }

    func consumeAnalysis() throws(AppError) {
        guard canUse(.analysis) else {
            throw AppError.paywallRequired(.analysis)
        }
        if !isPro {
            analysesUsed += 1
        }
    }

    func setProPreview(_ enabled: Bool) {
        isPro = enabled
    }

    func resetAll() {
        analysesUsed = 0
        isPro = false
        defaults.removeObject(forKey: usedKey)
        defaults.set(false, forKey: proKey)
    }
}
