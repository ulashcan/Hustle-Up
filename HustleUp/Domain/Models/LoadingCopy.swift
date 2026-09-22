import Foundation

enum LoadingPhase: Equatable, Sendable {
    case ocr
    case analysis
    case fumble
    case practice
}

enum LoadingCopy {
    static func messages(for phase: LoadingPhase) -> [String] {
        switch phase {
        case .ocr:
            return [
                "READING THE SCREENSHOT…",
                "PULLING THE TEXT…"
            ]
        case .analysis:
            return [
                "READING THE ROOM…",
                "FINDING YOUR EDGE…",
                "THINKING TWO MOVES AHEAD…"
            ]
        case .fumble:
            return [
                "CHECKING FOR FUMBLES…",
                "READING THE TONE…"
            ]
        case .practice:
            return [
                "THE OTHER SIDE IS TALKING…",
                "LET'S RUN IT."
            ]
        }
    }
}
