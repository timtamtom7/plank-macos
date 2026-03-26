import Foundation

/// R16: Subscription tiers for Plank
public enum PlankSubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case household = "household"
    
    public var displayName: String {
        switch self { case .free: return "Free"; case .pro: return "Plank Pro"; case .household: return "Plank Household" }
    }
    public var monthlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 3.99; case .household: return 6.99 }
    }
    public var maxBookmarks: Int? {
        switch self { case .free: return 100; case .pro: return nil; case .household: return nil }
    }
    public var supportsAdvancedCleaning: Bool { self != .free }
    public var supportsScheduledCleaning: Bool { self != .free }
    public var supportsWidgets: Bool { self != .free }
    public var supportsShortcuts: Bool { self != .free }
    public var trialDays: Int { self == .free ? 0 : 14 }
}

public struct PlankSubscription: Codable {
    public let tier: PlankSubscriptionTier
    public let status: String
    public let expiresAt: Date?
    public init(tier: PlankSubscriptionTier, status: String = "active", expiresAt: Date? = nil) {
        self.tier = tier; self.status = status; self.expiresAt = expiresAt
    }
}
