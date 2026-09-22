import Foundation

enum AppError: Error, Equatable, Sendable {
    case imageTooSmall
    case imageEmpty
    case imageUnsupported
    case ocrFailed
    case noTextDetected
    case emptyInput
    case inputTooLong
    case networkUnavailable
    case timedOut
    case rateLimited
    case modelUnavailable
    case malformedAIResponse
    case paywallRequired(Feature)
    case cancelled

    var title: String {
        switch self {
        case .imageTooSmall:
            return "That image is too small."
        case .imageEmpty:
            return "We couldn't read that screenshot."
        case .imageUnsupported:
            return "That file isn't a usable image."
        case .ocrFailed:
            return "We couldn't read that screenshot."
        case .noTextDetected:
            return "No text turned up in that image."
        case .emptyInput:
            return "There's nothing to analyze yet."
        case .inputTooLong:
            return "That's longer than we can take in one pass."
        case .networkUnavailable:
            return "We're offline."
        case .timedOut:
            return "That took too long."
        case .rateLimited:
            return "Too many moves too fast."
        case .modelUnavailable:
            return "The analysis didn't land."
        case .malformedAIResponse:
            return "That analysis came back messy."
        case .paywallRequired:
            return "That's a Pro move."
        case .cancelled:
            return "Cancelled."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .imageTooSmall, .imageEmpty, .imageUnsupported, .ocrFailed, .noTextDetected:
            return "Try a clearer image or paste the text instead."
        case .emptyInput:
            return "Type what happened, even if it's messy."
        case .inputTooLong:
            return "Keep the key messages. Cut the rest."
        case .networkUnavailable, .timedOut:
            return "Check the connection and try again."
        case .rateLimited:
            return "Wait a moment, then try again."
        case .modelUnavailable, .malformedAIResponse:
            return "Try again. If it keeps happening, type a shorter version."
        case .paywallRequired:
            return "Pro unlocks unlimited analyses, Fumble Check, Practice, and your move history."
        case .cancelled:
            return "Whenever you're ready."
        }
    }

    var recoveryActionTitle: String {
        switch self {
        case .imageTooSmall, .imageEmpty, .imageUnsupported, .ocrFailed, .noTextDetected:
            return "Type it instead"
        case .paywallRequired:
            return "See Pro"
        case .cancelled:
            return "OK"
        default:
            return "Try again"
        }
    }

    var analyticsCode: String {
        switch self {
        case .imageTooSmall: return "image_too_small"
        case .imageEmpty: return "image_empty"
        case .imageUnsupported: return "image_unsupported"
        case .ocrFailed: return "ocr_failed"
        case .noTextDetected: return "no_text"
        case .emptyInput: return "empty_input"
        case .inputTooLong: return "input_too_long"
        case .networkUnavailable: return "network"
        case .timedOut: return "timeout"
        case .rateLimited: return "rate_limited"
        case .modelUnavailable: return "model_unavailable"
        case .malformedAIResponse: return "malformed_ai"
        case .paywallRequired(let feature): return "paywall_\(feature.rawValue)"
        case .cancelled: return "cancelled"
        }
    }
}
