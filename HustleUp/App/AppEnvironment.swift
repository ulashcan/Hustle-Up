import Foundation

@Observable
@MainActor
final class AppEnvironment {
    let ai: any AIServicing
    let ocr: any OCRServicing
    let validator: any ImageValidating
    let store: any AnalysisStoring
    let entitlements: any EntitlementProviding
    let analytics: any AnalyticsTracking
    let skipOnboardingDefault: Bool

    init(
        ai: any AIServicing,
        ocr: any OCRServicing,
        validator: any ImageValidating,
        store: any AnalysisStoring,
        entitlements: any EntitlementProviding,
        analytics: any AnalyticsTracking,
        skipOnboardingDefault: Bool = false
    ) {
        self.ai = ai
        self.ocr = ocr
        self.validator = validator
        self.store = store
        self.entitlements = entitlements
        self.analytics = analytics
        self.skipOnboardingDefault = skipOnboardingDefault
    }

    static func bootstrap(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        let uiTesting = arguments.contains("-ui-testing")
        let skipOnboarding = arguments.contains("-skip-onboarding")
        let pro = arguments.contains("-pro")
        let fresh = arguments.contains("-fresh-install")

        if fresh {
            UserDefaults.standard.removeObject(forKey: "hu.onboardingComplete")
        }

        let ai: any AIServicing
        if arguments.contains("-ai-fail") {
            ai = FailingAIService(error: .networkUnavailable)
        } else if arguments.contains("-ai-timeout") {
            ai = FailingAIService(error: .timedOut)
        } else if arguments.contains("-ai-malformed") {
            ai = MalformedPayloadAIService()
        } else if let live = LiveAIService.configured() {
            ai = live
        } else {
            ai = MockAIService(delay: uiTesting ? .zero : .milliseconds(700))
        }

        let defaults: UserDefaults
        if uiTesting || fresh {
            let suite = "hu.uitesting.\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suite) ?? .standard
            defaults.removePersistentDomain(forName: suite)
        } else {
            defaults = .standard
        }

        let entitlements = EntitlementStore(defaults: defaults)
        if pro {
            entitlements.setProPreview(true)
        }

        let store: FileAnalysisStore
        if uiTesting {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("hu-ui-\(UUID().uuidString).json")
            store = FileAnalysisStore(fileURL: url)
        } else {
            store = FileAnalysisStore()
        }

        return AppEnvironment(
            ai: ai,
            ocr: VisionOCRService(),
            validator: ImageValidator(),
            store: store,
            entitlements: entitlements,
            analytics: InMemoryAnalytics(),
            skipOnboardingDefault: skipOnboarding
        )
    }
}
