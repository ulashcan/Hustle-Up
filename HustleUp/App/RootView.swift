import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        ZStack {
            HUTheme.background.ignoresSafeArea()
            if model.showOnboarding {
                OnboardingView()
            } else {
                NavigationStack(path: $model.path) {
                    HomeView()
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .compose:
                                ComposeView()
                            case .ocrReview:
                                OCRReviewView()
                            case .analysis:
                                AnalysisView()
                            case .fumble:
                                FumbleCheckView()
                            case .practice:
                                PracticeView()
                            case .scorecard:
                                ScorecardView()
                            case .settings:
                                SettingsView()
                            case .profile:
                                ProfileView()
                            }
                        }
                }
                .toolbarBackground(HUTheme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .tint(HUTheme.accent)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                model.cancelLoading()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if model.error != nil {
                HUErrorView(
                    error: model.error,
                    onAction: { model.handleErrorAction() },
                    onDismiss: { model.error = nil }
                )
                .padding(.horizontal, HUTheme.space16)
                .padding(.bottom, HUTheme.space8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if let phase = model.loading {
                HULoadingView(phase: phase, onCancel: { model.cancelLoading() })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.error)
        .animation(.easeInOut(duration: 0.2), value: model.loading)
        .sensoryFeedback(.success, trigger: model.showOnboarding)
        .sheet(isPresented: $model.showPaywall) {
            PaywallView()
                .presentationDetents([.medium, .large])
                .preferredColorScheme(.dark)
        }
    }
}
