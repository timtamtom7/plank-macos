import Foundation

struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: StartupItemType
    var isEnabled: Bool
}

enum StartupItemType: String {
    case application
    case loginItem
    case extension_
}

final class StartupManager {
    static let shared = StartupManager()

    private init() {}

    func fetchStartupItems() -> [StartupItem] {
        var items: [StartupItem] = []

        // Look in ~/Library/Application Support/com.apple.backgroundtaskmanagementagent/
        let home = FileManager.default.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")

        let loginItemsURL = library.appendingPathComponent("LoginItems")
        if FileManager.default.fileExists(atPath: loginItemsURL.path) {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: loginItemsURL.path) {
                for item in contents {
                    let url = loginItemsURL.appendingPathComponent(item)
                    items.append(StartupItem(
                        name: item,
                        path: url.path,
                        type: .loginItem,
                        isEnabled: true
                    ))
                }
            }
        }

        return items
    }

    func setEnabled(_ item: StartupItem, enabled: Bool) {
        // In a real implementation, this would modify system settings
        print("Setting \(item.name) enabled: \(enabled)")
    }
}
