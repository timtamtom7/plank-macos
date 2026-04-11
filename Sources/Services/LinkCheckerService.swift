import Foundation
import os.log

// MARK: - Link Check Result

struct LinkCheckResult: Identifiable, Codable {
    var id: UUID
    var bookmarkId: Int64
    var status: LinkStatus
    var statusCode: Int?
    var checkedAt: Date
    var responseTimeMs: Int?

    init(bookmarkId: Int64, status: LinkStatus, statusCode: Int? = nil, responseTimeMs: Int? = nil) {
        self.id = UUID()
        self.bookmarkId = bookmarkId
        self.status = status
        self.statusCode = statusCode
        self.checkedAt = Date()
        self.responseTimeMs = responseTimeMs
    }
}

// MARK: - Link Checker Service

final class LinkCheckerService: ObservableObject {
    static let shared = LinkCheckerService()

    private let logger = Logger(subsystem: "com.plank.app", category: "LinkChecker")
    private var checkTasks: [Int64: Task<Void, Never>] = [:]
    private let resultsKey = "linkCheckResults"
    private var cachedResults: [Int64: LinkCheckResult] = [:]

    @Published var isChecking = false
    @Published var lastCheckDate: Date?

    var onResultsUpdated: (([LinkCheckResult]) -> Void)?

    private init() {
        loadCachedResults()
    }

    // MARK: - Public API

    /// Check a single bookmark's URL
    func checkLink(_ bookmark: Bookmark) {
        guard let urlString = bookmark.url, let url = URL(string: urlString) else {
            saveResult(LinkCheckResult(bookmarkId: bookmark.id ?? 0, status: .broken))
            return
        }
        performCheck(bookmarkId: bookmark.id ?? 0, url: url)
    }

    /// Check all weblink bookmarks
    func checkAllLinks() {
        let bookmarks = BookmarkStore.shared.getAll().filter { $0.type == .weblink && $0.url != nil }
        guard !bookmarks.isEmpty else { return }

        isChecking = true
        logger.info("Starting link check for \(bookmarks.count) bookmarks")

        Task {
            for bookmark in bookmarks {
                guard let urlString = bookmark.url, let url = URL(string: urlString) else {
                    let result = LinkCheckResult(bookmarkId: bookmark.id ?? 0, status: .broken)
                    await MainActor.run { self.saveResult(result) }
                    continue
                }
                let result = await performCheckAsync(bookmarkId: bookmark.id ?? 0, url: url)
                await MainActor.run { self.saveResult(result) }

                // Small delay to avoid hammering servers
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            await MainActor.run {
                self.isChecking = false
                self.lastCheckDate = Date()
                self.persistCachedResults()
                self.logger.info("Link check complete. Checked \(bookmarks.count) bookmarks")
            }
        }
    }

    /// Cancel all ongoing checks
    func cancelAll() {
        checkTasks.values.forEach { $0.cancel() }
        checkTasks.removeAll()
        isChecking = false
    }

    /// Get cached result for a bookmark
    func result(for bookmarkId: Int64) -> LinkCheckResult? {
        return cachedResults[bookmarkId]
    }

    /// Get summary counts
    var summary: (total: Int, valid: Int, broken: Int, unknown: Int) {
        let results = Array(cachedResults.values)
        let total = results.count
        let valid = results.filter { $0.status == .valid }.count
        let broken = results.filter { $0.status == .broken || $0.status == .timeout }.count
        let unknown = results.filter { $0.status == .unknown || $0.status == .checking }.count
        return (total, valid, broken, unknown)
    }

    // MARK: - Private

    private func performCheck(bookmarkId: Int64, url: URL) {
        let task = Task { [weak self] in
            guard let self = self else { return }
            let result = await self.performCheckAsync(bookmarkId: bookmarkId, url: url)
            await MainActor.run { self.saveResult(result) }
        }
        checkTasks[bookmarkId] = task
    }

    private func performCheckAsync(bookmarkId: Int64, url: URL) async -> LinkCheckResult {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let startTime = Date()

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)

            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                let status: LinkStatus
                switch statusCode {
                case 200..<400:
                    status = .valid
                case 400..<500:
                    status = .broken
                case 500..<600:
                    status = .broken
                default:
                    status = statusCode >= 300 ? .redirected : .valid
                }
                return LinkCheckResult(bookmarkId: bookmarkId, status: status, statusCode: statusCode, responseTimeMs: elapsed)
            } else {
                return LinkCheckResult(bookmarkId: bookmarkId, status: .unknown, responseTimeMs: elapsed)
            }
        } catch let error as NSError {
            let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
            let status: LinkStatus = (error.code == NSURLErrorTimedOut) ? .timeout : .broken
            return LinkCheckResult(bookmarkId: bookmarkId, status: status, responseTimeMs: elapsed)
        }
    }

    private func saveResult(_ result: LinkCheckResult) {
        cachedResults[result.bookmarkId] = result
        // Persist to DB
        BookmarkStore.shared.updateLinkStatus(result.bookmarkId, status: result.status)
        onResultsUpdated?(Array(cachedResults.values))
    }

    private func loadCachedResults() {
        guard let data = UserDefaults.standard.data(forKey: resultsKey) else { return }
        do {
            let results = try JSONDecoder().decode([LinkCheckResult].self, from: data)
            cachedResults = Dictionary(uniqueKeysWithValues: results.map { ($0.bookmarkId, $0) })
        } catch {
            logger.error("Failed to load cached link check results: \(error.localizedDescription)")
        }
    }

    private func persistCachedResults() {
        do {
            let data = try JSONEncoder().encode(Array(cachedResults.values))
            UserDefaults.standard.set(data, forKey: resultsKey)
        } catch {
            logger.error("Failed to persist link check results: \(error.localizedDescription)")
        }
    }
}
