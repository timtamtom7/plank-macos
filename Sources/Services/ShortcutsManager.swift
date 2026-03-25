import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct PlankShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetBookmarkCountIntent(),
            phrases: [
                "Get \(.applicationName) bookmark count",
                "How many bookmarks in \(.applicationName)"
            ],
            shortTitle: "Bookmark Count",
            systemImageName: "bookmark.fill"
        )

        AppShortcut(
            intent: OpenSidebarIntent(),
            phrases: [
                "Open \(.applicationName) sidebar",
                "Open \(.applicationName)"
            ],
            shortTitle: "Open Sidebar",
            systemImageName: "sidebar.right"
        )
    }
}

// MARK: - Get Bookmark Count Intent

struct GetBookmarkCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Bookmark Count"
    static var description = IntentDescription("Returns the total number of bookmarks in Plank")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let count = await PlankState.shared.bookmarks.count
        return .result(value: count, dialog: "Plank has \(count) bookmarks")
    }
}

// MARK: - Open Sidebar Intent

struct OpenSidebarIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Plank Sidebar"
    static var description = IntentDescription("Opens the Plank sidebar")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening Plank sidebar")
    }
}
