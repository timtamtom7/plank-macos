import Foundation

@MainActor
final class PlankSyncManager: ObservableObject {
    static let shared = PlankSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var bookmarks: [Bookmark]
        var settings: PlankSettings

        struct PlankSettings: Codable {
            var showFavorites: Bool
            var showHistory: Bool
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "plank.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "plank.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.PlankSettings(
            showFavorites: UserDefaults.standard.bool(forKey: "plank_showFavorites"),
            showHistory: UserDefaults.standard.bool(forKey: "plank_showHistory")
        )

        return SyncPayload(
            bookmarks: PlankState.shared.bookmarks,
            settings: settings
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        PlankState.shared.bookmarks = payload.bookmarks

        UserDefaults.standard.set(payload.settings.showFavorites, forKey: "plank_showFavorites")
        UserDefaults.standard.set(payload.settings.showHistory, forKey: "plank_showHistory")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
