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
                    saveResult(LinkCheckResult(bookmarkId: bookmark.id ?? 0, status: .broken))
                    continue
                }
                performCheckSynchronous(bookmarkId: bookmark.id ?? 0, url: url)

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
            await self.performCheckSynchronous(bookmarkId: bookmarkId, url: url)
        }
        checkTasks[bookmarkId] = task
    }

    private func performCheckSynchronous(bookmarkId: Int64, url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let startTime = Date()

        let semaphore = DispatchSemaphore(value: 0)
        var resultStatus: LinkStatus = .unknown
        var resultCode: Int?
        var responseTime: Int?

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        let session = URLSession(configuration: config)

        let urlTask = session.dataTask(with: request) { _, response, error in
            let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
            responseTime = elapsed

            if let error = error {
                let nsError = error as NSError
                if nsError.code == NSURLErrorTimedOut {
                    resultStatus = .timeout
                } else {
                    resultStatus = .broken
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                resultCode = httpResponse.statusCode
                switch httpResponse.statusCode {
                case 200..<400:
                    resultStatus = .valid
                case 400..<500:
                    resultStatus = .broken
                case 500..<600:
                    resultStatus = .broken
                default:
                    if httpResponse.statusCode >= 300 {
                        resultStatus = .redirected
                    } else {
                        resultStatus = .valid
                    }
                }
            } else {
                resultStatus = .unknown
            }

            semaphore.signal()
        }

        urlTask.resume()

        // Wait with timeout
        _ = semaphore.wait(timeout: .now() + 10)

        let result = LinkCheckResult(
            bookmarkId: bookmarkId,
            status: resultStatus,
            statusCode: resultCode,
            responseTimeMs: responseTime
        )

        DispatchQueue.main.async { [weak self] in
            self?.saveResult(result)
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
