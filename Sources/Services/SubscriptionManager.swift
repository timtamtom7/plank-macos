import Foundation
import StoreKit

@available(macOS 13.0, *)
public final class PlankSubscriptionManager: ObservableObject {
    public static let shared = PlankSubscriptionManager()
    @Published public private(set) var subscription: PlankSubscription?
    @Published public private(set) var products: [Product] = []
    private init() {}
    public func loadProducts() async {
        do { products = try await Product.products(for: ["com.plank.macos.pro.monthly","com.plank.macos.pro.yearly","com.plank.macos.household.monthly","com.plank.macos.household.yearly"]) }
        catch { print("Failed to load products") }
    }
    public func canAccess(_ feature: PlankFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .advancedCleaning: return sub.tier != .free
        case .scheduledCleaning: return sub.tier != .free
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        }
    }
    public func updateStatus() async {
        var found: PlankSubscription = PlankSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("household") { found = PlankSubscription(tier: .household, status: t.revocationDate == nil ? "active" : "expired") }
                else if t.productID.contains("pro") { found = PlankSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired") }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    public func restore() async throws { try await AppStore.sync(); await updateStatus() }
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T { switch r { case .unverified: throw NSError(domain: "Plank", code: -1); case .verified(let s): return s } }
}
public enum PlankFeature { case advancedCleaning, scheduledCleaning, widgets, shortcuts }
