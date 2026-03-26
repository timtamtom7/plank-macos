import Foundation

/// AI-powered widget intelligence for Plank dock sidebar
final class WidgetIntelligenceEngine {
    static let shared = WidgetIntelligenceEngine()
    
    private init() {}
    
    // MARK: - Widget Ranking
    
    /// Suggest optimal widget order based on usage patterns
    func suggestWidgetOrder(widgets: [Widget], usageHistory: [String: Int]) -> [Widget] {
        return widgets.sorted { w1, w2 in
            let score1 = usageHistory[w1.id] ?? 0
            let score2 = usageHistory[w2.id] ?? 0
            return score1 > score2
        }
    }
    
    // MARK: - Usage Prediction
    
    /// Predict which widget user will need at current time
    func predictWidget(for hour: Int) -> String? {
        // Morning: weather/news
        if hour >= 7 && hour <= 9 {
            return "weather"
        }
        // Work hours: calendar/tasks
        if hour >= 9 && hour <= 17 {
            return "calendar"
        }
        // Evening: music/media
        if hour >= 18 && hour <= 22 {
            return "music"
        }
        return nil
    }
}

// MARK: - Widget Protocol

protocol Widget: Identifiable {
    var id: String { get }
    var name: String { get }
}
