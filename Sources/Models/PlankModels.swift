import Foundation

// MARK: - Plank R12-R15 Models

struct BookmarkItemCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var bookmarks: [BookmarkItem]
    var sharedWith: [String]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, bookmarks: [BookmarkItem] = [], sharedWith: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.bookmarks = bookmarks
        self.sharedWith = sharedWith
        self.createdAt = createdAt
    }
}

struct BookmarkItem: Identifiable, Codable {
    let id: UUID
    var url: String
    var title: String
    var description: String?
    var tags: [String]
    var favicon: String?
    var previewImage: String?
    var createdAt: Date
    var lastVisited: Date?
    var visitCount: Int

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        description: String? = nil,
        tags: [String] = [],
        favicon: String? = nil,
        previewImage: String? = nil,
        createdAt: Date = Date(),
        lastVisited: Date? = nil,
        visitCount: Int = 0
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.description = description
        self.tags = tags
        self.favicon = favicon
        self.previewImage = previewImage
        self.createdAt = createdAt
        self.lastVisited = lastVisited
        self.visitCount = visitCount
    }
}

struct ShareLink: Identifiable, Codable {
    let id: UUID
    var collectionId: UUID
    var code: String
    var expiresAt: Date?
    var accessCount: Int

    init(id: UUID = UUID(), collectionId: UUID, code: String = String(UUID().uuidString.prefix(8)).uppercased(), expiresAt: Date? = nil, accessCount: Int = 0) {
        self.id = id
        self.collectionId = collectionId
        self.code = code
        self.expiresAt = expiresAt
        self.accessCount = accessCount
    }
}

struct CleanupTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: CleanupType
    var isEnabled: Bool

    enum CleanupType: String, Codable {
        case brokenLinks
        case duplicates
        case oldBookmarkItems
        case unusedTags
    }

    init(id: UUID = UUID(), name: String, type: CleanupType, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.isEnabled = isEnabled
    }
}

struct CleanupReport: Identifiable, Codable {
    let id: UUID
    var taskType: CleanupTask.CleanupType
    var itemsFound: Int
    var itemsRemoved: Int
    var completedAt: Date

    init(id: UUID = UUID(), taskType: CleanupTask.CleanupType, itemsFound: Int = 0, itemsRemoved: Int = 0, completedAt: Date = Date()) {
        self.id = id
        self.taskType = taskType
        self.itemsFound = itemsFound
        self.itemsRemoved = itemsRemoved
        self.completedAt = completedAt
    }
}
