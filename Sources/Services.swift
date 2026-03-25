import Foundation

// MARK: - Tag

struct Tag: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String

    init(id: UUID = UUID(), name: String, color: String = "#007AFF") {
        self.id = id
        self.name = name
        self.color = color
    }
}

// MARK: - Bookmark Folder

struct BookmarkFolder: Identifiable, Codable {
    var id: UUID
    var name: String
    var bookmarkIds: [Int64]
    var isExpanded: Bool

    init(id: UUID = UUID(), name: String, bookmarkIds: [Int64] = [], isExpanded: Bool = true) {
        self.id = id
        self.name = name
        self.bookmarkIds = bookmarkIds
        self.isExpanded = isExpanded
    }
}

// MARK: - Visit Record

struct VisitRecord: Identifiable, Codable {
    let id: UUID
    let bookmarkId: Int64
    let visitedAt: Date

    init(bookmarkId: Int64, visitedAt: Date = Date()) {
        self.id = UUID()
        self.bookmarkId = bookmarkId
        self.visitedAt = visitedAt
    }
}

// MARK: - Search Service

@MainActor
final class SearchService: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Bookmark] = []

    private let store = BookmarkStore.shared

    func search() {
        guard !query.isEmpty else {
            results = []
            return
        }
        let all = store.getAll()
        results = all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - History Service

@MainActor
final class HistoryService: ObservableObject {
    @Published var recentVisits: [VisitRecord] = []
    @Published var mostVisited: [(Bookmark, Int)] = []

    private let store = BookmarkStore.shared
    private var allVisits: [VisitRecord] = []

    func recordVisit(bookmarkId: Int64) {
        let record = VisitRecord(bookmarkId: bookmarkId)
        allVisits.insert(record, at: 0)
        if allVisits.count > 100 {
            allVisits = Array(allVisits.prefix(100))
        }
        updateMostVisited()
    }

    private func updateMostVisited() {
        var counts: [Int64: Int] = [:]
        for visit in allVisits {
            counts[visit.bookmarkId] = (counts[visit.bookmarkId] ?? 0) + 1
        }
        let allBookmarks = store.getAll()
        mostVisited = counts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .compactMap { bid, count in
                if let bookmark = allBookmarks.first(where: { $0.id == bid }) {
                    return (bookmark, count)
                }
                return nil
            }
    }
}
