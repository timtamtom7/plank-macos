import Foundation
import AppKit

/// Import/Export service for Plank bookmarks
final class ImportExportService {
    static let shared = ImportExportService()

    private init() {}

    // MARK: - Export

    struct ExportPayload: Codable {
        let version: Int = 1
        let exportDate: Date
        let bookmarks: [Bookmark]
    }

    func exportBookmarks(_ bookmarks: [Bookmark]) throws -> Data {
        let payload = ExportPayload(exportDate: Date(), bookmarks: bookmarks)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    func exportToFile(_ bookmarks: [Bookmark]) throws -> URL {
        let data = try exportBookmarks(bookmarks)

        let tempDir = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Plank-Bookmarks-\(dateFormatter.string(from: Date())).json"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }

    // MARK: - Import

    func importBookmarks(from data: Data) throws -> [Bookmark] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(ExportPayload.self, from: data)
        return payload.bookmarks
    }

    func importFromFile(_ url: URL) throws -> [Bookmark] {
        let data = try Data(contentsOf: url)
        return try importBookmarks(from: data)
    }

    // MARK: - File Panel

    func showExportPanel(completion: @escaping (URL?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "Plank-Bookmarks.json"
        savePanel.canCreateDirectories = true

        if savePanel.runModal() == .OK {
            completion(savePanel.url)
        } else {
            completion(nil)
        }
    }

    func showImportPanel(completion: @escaping ([Bookmark]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let bookmarks = try importFromFile(url)
                completion(bookmarks)
            } catch {
                print("Import failed: \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
}
