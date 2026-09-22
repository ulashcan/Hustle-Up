import Foundation

enum Route: Hashable {
    case compose
    case ocrReview
    case analysis
    case fumble
    case practice
    case scorecard
    case settings
    case profile
}

enum ExamplePrompt: String, CaseIterable, Identifiable, Sendable {
    case bossOffer
    case shouldReply
    case clientDiscount
    case argument

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bossOffer: "Boss put an offer down"
        case .shouldReply: "Should I reply?"
        case .clientDiscount: "Client wants a cut"
        case .argument: "We're in a fight"
        }
    }

    var seed: String {
        switch self {
        case .bossOffer:
            return "My boss made an offer. 90k. I haven't answered."
        case .shouldReply:
            return "Should I reply?"
        case .clientDiscount:
            return "Client wants a discount on the remaining work."
        case .argument:
            return "We're having an argument. I already drafted a long reply."
        }
    }
}

enum HUID {
    static let homeHeadline = "home.headline"
    static let homeRemaining = "home.remaining"
    static let homeLastMove = "home.lastMove"
    static let homeOutcome = "home.outcome"
    static let homeProfile = "home.profile"
    static let outcomeYes = "outcome.yes"
    static let outcomeNo = "outcome.no"
    static let outcomePartly = "outcome.partly"
    static let outcomeNotSure = "outcome.notSure"
    static let profileRoot = "profile.root"
    static let analysisOutcome = "analysis.outcome"
    static let homeUnlock = "home.unlock"
    static let homeSettings = "home.settings"
    static let analysisReadToggle = "analysis.readToggle"
    static let analysisCopy = "analysis.copy"
    static let analysisSayThis = "analysis.sayThis"
    static let analysisHold = "analysis.hold"
    static let analysisEdgeMap = "analysis.edgeMap"
    static let analysisOtherMoves = "analysis.otherMoves"
    static let analysisNeedContext = "analysis.needContext"
    static let analysisAddDetail = "analysis.addDetail"
    static let loadingCancel = "loading.cancel"
    static let ocrTypeInstead = "ocr.typeInstead"
    static let homeScreenshot = "home.screenshot"
    static let homeType = "home.type"
    static let composeText = "compose.text"
    static let composeAnalyze = "compose.analyze"
    static let ocrText = "ocr.text"
    static let ocrAnalyze = "ocr.analyze"
    static let analysisMove = "analysis.move"
    static let analysisPractice = "analysis.practice"
    static let analysisFumble = "analysis.fumble"
    static let analysisDone = "analysis.done"
    static let fumbleText = "fumble.text"
    static let fumbleRun = "fumble.run"
    static let fumbleVerdict = "fumble.verdict"
    static let fumbleCopy = "fumble.copy"
    static let practiceInput = "practice.input"
    static let practiceSend = "practice.send"
    static let practiceFinish = "practice.finish"
    static let scorecard = "practice.scorecard"
    static let paywall = "paywall.root"
    static let paywallPreview = "paywall.preview"
    static let settings = "settings.root"
    static let onboardingContinue = "onboarding.continue"
    static let errorBanner = "error.banner"
    static let errorAction = "error.action"
}
