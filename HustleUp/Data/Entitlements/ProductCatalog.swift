import Foundation

/// Product identifiers and entitlement mapping for a future StoreKit 2 integration.
/// Purchases are NOT live. Do not present these IDs as buyable until signed StoreKit
/// purchase + restore have been tested on a paid Apple team.
enum ProductCatalog {
    static let proMonthly = "com.hustleup.pro.monthly"
    static let proYearly = "com.hustleup.pro.yearly"

    static let allIdentifiers: [String] = [proMonthly, proYearly]

    static func unlocks(for productID: String) -> Set<Feature> {
        switch productID {
        case proMonthly, proYearly:
            return [.analysis, .fumbleCheck, .practice, .history, .advancedAnalysis]
        default:
            return []
        }
    }
}

protocol StorePurchasing: Sendable {
    func purchase(productID: String) async throws
    func restore() async throws
}

/// Stand-in until StoreKit is wired. Always fails closed — never silently grants Pro.
struct UnimplementedStore: StorePurchasing {
    func purchase(productID: String) async throws {
        _ = productID
        throw AppError.paywallRequired(.analysis)
    }

    func restore() async throws {
        throw AppError.paywallRequired(.analysis)
    }
}
