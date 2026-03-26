import Foundation
import SQLite

// MARK: - Bookmark Type

enum BookmarkType: String, Codable {
    case weblink
    case folder
    case app
}

// MARK: - Bookmark Model

struct Bookmark: Identifiable, Codable {
    var id: Int64?
    var name: String
    var url: String?
    var path: String?
    var icon: String
    var position: Int
    var type: BookmarkType
    var isPinned: Bool

    init(id: Int64? = nil, name: String, url: String? = nil, path: String? = nil, icon: String, position: Int, type: BookmarkType, isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.url = url
        self.path = path
        self.icon = icon
        self.position = position
        self.type = type
        self.isPinned = isPinned
    }
}

// MARK: - Bookmark Store (SQLite.swift)

class BookmarkStore {

    static let shared = BookmarkStore()

    private var db: Connection?

    // Table definition
    private let bookmarks = Table("bookmarks")
    private let id = SQLite.Expression<Int64>("id")
    private let name = SQLite.Expression<String>("name")
    private let url = SQLite.Expression<String?>("url")
    private let path = SQLite.Expression<String?>("path")
    private let icon = SQLite.Expression<String>("icon")
    private let position = SQLite.Expression<Int>("position")
    private let type = SQLite.Expression<String>("type")
    private let isPinned = SQLite.Expression<Bool>("is_pinned")

    private init() {}

    func initialize() {
        do {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appFolder = appSupport.appendingPathComponent("Plank", isDirectory: true)
            try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
            let dbPath = appFolder.appendingPathComponent("plank.db").path
            db = try Connection(dbPath)
            createTable()
        } catch {
            print("BookmarkStore: Failed to initialize: \(error)")
        }
    }

    private func createTable() {
        do {
            try db?.run(bookmarks.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(name)
                t.column(url)
                t.column(path)
                t.column(icon)
                t.column(position)
                t.column(type)
                t.column(isPinned, defaultValue: false)
            })
        } catch {
            print("BookmarkStore: Failed to create table: \(error)")
        }
    }

    // MARK: - CRUD

    func getAll() -> [Bookmark] {
        var result: [Bookmark] = []
        do {
            guard let db = db else { return [] }
            for row in try db.prepare(bookmarks.order(position.asc)) {
                let bookmark = Bookmark(
                    id: row[id],
                    name: row[name],
                    url: row[url],
                    path: row[path],
                    icon: row[icon],
                    position: row[position],
                    type: BookmarkType(rawValue: row[type]) ?? .weblink,
                    isPinned: row[isPinned]
                )
                result.append(bookmark)
            }
        } catch {
            print("BookmarkStore: Failed to get all: \(error)")
        }
        return result
    }

    func insert(_ bookmark: Bookmark) -> Int64? {
        do {
            guard let db = db else { return nil }
            let insert = bookmarks.insert(
                name <- bookmark.name,
                url <- bookmark.url,
                path <- bookmark.path,
                icon <- bookmark.icon,
                position <- bookmark.position,
                type <- bookmark.type.rawValue,
                isPinned <- bookmark.isPinned
            )
            return try db.run(insert)
        } catch {
            print("BookmarkStore: Failed to insert: \(error)")
            return nil
        }
    }

    func update(_ bookmark: Bookmark) {
        guard let bookmarkId = bookmark.id else { return }
        do {
            guard let db = db else { return }
            let row = bookmarks.filter(id == bookmarkId)
            try db.run(row.update(
                name <- bookmark.name,
                url <- bookmark.url,
                path <- bookmark.path,
                icon <- bookmark.icon,
                position <- bookmark.position,
                type <- bookmark.type.rawValue,
                isPinned <- bookmark.isPinned
            ))
        } catch {
            print("BookmarkStore: Failed to update: \(error)")
        }
    }

    func delete(_ bookmarkId: Int64) {
        do {
            guard let db = db else { return }
            let row = bookmarks.filter(id == bookmarkId)
            try db.run(row.delete())
        } catch {
            print("BookmarkStore: Failed to delete: \(error)")
        }
    }

    func reorder(_ reordered: [Bookmark]) {
        guard let db = db else { return }
        for (index, var bookmark) in reordered.enumerated() {
            bookmark.position = index
            if let bid = bookmark.id {
                do {
                    let row = bookmarks.filter(id == bid)
                    try db.run(row.update(position <- index))
                } catch {
                    print("BookmarkStore: Failed to reorder: \(error)")
                }
            }
        }
    }

    func getPinnedApps() -> [Bookmark] {
        return getAll().filter { $0.isPinned }
    }

    func getBookmarks() -> [Bookmark] {
        return getAll().filter { !$0.isPinned }
    }
}
