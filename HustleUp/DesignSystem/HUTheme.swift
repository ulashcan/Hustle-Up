import SwiftUI

enum HUTheme {
    static let background = Color(red: 0.02, green: 0.02, blue: 0.025)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.095)
    static let surfaceRaised = Color(red: 0.13, green: 0.13, blue: 0.14)
    static let text = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let muted = Color(red: 0.62, green: 0.60, blue: 0.56)
    static let accent = Color(red: 0.91, green: 0.72, blue: 0.29)
    static let danger = Color(red: 0.93, green: 0.32, blue: 0.26)
    static let go = Color(red: 0.42, green: 0.78, blue: 0.50)
    static let line = Color.white.opacity(0.08)

    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space48: CGFloat = 48

    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
}

enum HUButtonKind {
    case primary
    case secondary
    case ghost
    case danger
}

struct HUPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct HUButton: View {
    var title: String
    var kind: HUButtonKind = .primary
    var systemImage: String?
    var identifier: String?
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HUTheme.space8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, HUTheme.space16)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(.rect(cornerRadius: HUTheme.radiusM))
            .overlay {
                if kind == .secondary || kind == .ghost {
                    RoundedRectangle(cornerRadius: HUTheme.radiusM, style: .continuous)
                        .stroke(HUTheme.line, lineWidth: 1)
                }
            }
        }
        .buttonStyle(HUPressStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier ?? title)
    }

    private var background: Color {
        switch kind {
        case .primary: HUTheme.accent
        case .secondary: HUTheme.surfaceRaised
        case .ghost: Color.clear
        case .danger: HUTheme.danger
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: Color.black
        case .danger: Color.white
        default: HUTheme.text
        }
    }
}

struct HUStickyBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(HUTheme.line)
                .frame(height: 1)
            VStack(spacing: HUTheme.space12) {
                content
            }
            .padding(.horizontal, HUTheme.space24)
            .padding(.top, HUTheme.space12)
            .padding(.bottom, HUTheme.space12)
        }
        .background(HUTheme.background)
    }
}

struct HUCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(HUTheme.space16)
            .background(HUTheme.surface)
            .clipShape(.rect(cornerRadius: HUTheme.radiusM))
    }
}

struct HUBadge: View {
    var text: String
    var tone: Tone = .neutral

    enum Tone {
        case neutral, accent, danger, go
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .tracking(0.6)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(foreground.opacity(0.14))
            .clipShape(.rect(cornerRadius: HUTheme.radiusS))
    }

    private var foreground: Color {
        switch tone {
        case .neutral: HUTheme.muted
        case .accent: HUTheme.accent
        case .danger: HUTheme.danger
        case .go: HUTheme.go
        }
    }
}

struct HUSectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.4)
            .foregroundStyle(HUTheme.muted)
    }
}

struct HULoadingView: View {
    var phase: LoadingPhase
    var onCancel: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    var body: some View {
        let messages = LoadingCopy.messages(for: phase)
        ZStack {
            HUTheme.background.opacity(0.92).ignoresSafeArea()
            VStack(spacing: HUTheme.space16) {
                Text(messages[index % messages.count])
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(messages[index % messages.count])
                if !reduceMotion {
                    Rectangle()
                        .fill(HUTheme.accent)
                        .frame(width: 48, height: 3)
                }
                Button("STOP") {
                    onCancel()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(HUTheme.muted)
                .frame(minHeight: 44)
                .accessibilityIdentifier(HUID.loadingCancel)
            }
            .padding(HUTheme.space32)
        }
        .task(id: phase) {
            index = 0
            guard !reduceMotion, messages.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1400))
                index += 1
            }
        }
    }
}

struct HUErrorView: View {
    var error: AppError?
    var onAction: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        if let error {
            VStack(alignment: .leading, spacing: HUTheme.space12) {
                Text(error.title)
                    .font(.headline)
                    .foregroundStyle(HUTheme.text)
                Text(error.recoverySuggestion)
                    .font(.subheadline)
                    .foregroundStyle(HUTheme.muted)
                HStack {
                    Button(error.recoveryActionTitle, action: onAction)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier(HUID.errorAction)
                    Spacer()
                    Button("Dismiss", action: onDismiss)
                        .font(.subheadline)
                        .foregroundStyle(HUTheme.muted)
                        .frame(minHeight: 44)
                }
            }
            .padding(HUTheme.space16)
            .background(HUTheme.surfaceRaised)
            .clipShape(.rect(cornerRadius: HUTheme.radiusM))
            .overlay {
                RoundedRectangle(cornerRadius: HUTheme.radiusM, style: .continuous)
                    .stroke(HUTheme.danger.opacity(0.4), lineWidth: 1)
            }
            .accessibilityIdentifier(HUID.errorBanner)
            .accessibilityElement(children: .contain)
        }
    }
}
