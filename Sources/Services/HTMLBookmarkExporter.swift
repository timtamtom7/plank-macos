import Foundation
import AppKit
import os.log

/// Exports Plank bookmarks to standard Netscape HTML Bookmark format
/// Compatible with Chrome, Safari, Firefox, and other browsers
final class HTMLBookmarkExporter {
    static let shared = HTMLBookmarkExporter()

    private let logger = Logger(subsystem: "com.plank.app", category: "HTMLExporter")

    private init() {}

    // MARK: - Public API

    /// Export all bookmarks to Netscape HTML format
    func exportToHTML(bookmarks: [Bookmark], title: String = "Plank Bookmarks") -> String {
        var html = buildHeader(title: title)

        // Separate pinned and regular bookmarks
        let pinnedApps = bookmarks.filter { $0.isPinned }
        let regularBookmarks = bookmarks.filter { !$0.isPinned }

        // Export regular bookmarks as "Bookmarks Bar"
        if !regularBookmarks.isEmpty {
            html += buildFolder(name: "Bookmarks", bookmarks: regularBookmarks, addDate: Date())
        }

        // Export pinned apps as a folder
        if !pinnedApps.isEmpty {
            html += buildFolder(name: "Pinned Apps", bookmarks: pinnedApps, addDate: Date())
        }

        html += buildFooter()
        return html
    }

    /// Save HTML bookmarks to a file and return the URL
    func saveToFile(bookmarks: [Bookmark], title: String = "Plank Bookmarks") -> URL? {
        let html = exportToHTML(bookmarks: bookmarks, title: title)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.nameFieldStringValue = "Plank-Bookmarks.html"
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            logger.info("Export cancelled by user")
            return nil
        }

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            logger.info("Exported \(bookmarks.count) bookmarks to \(url.lastPathComponent)")
            return url
        } catch {
            logger.error("Failed to write HTML export: \(error.localizedDescription)")
            return nil
        }
    }

    /// Quick export to desktop
    func quickExportToDesktop(bookmarks: [Bookmark]) -> URL? {
        let html = exportToHTML(bookmarks: bookmarks, title: "Plank Bookmarks")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Plank-Bookmarks-\(dateFormatter.string(from: Date())).html"

        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try html.write(to: fileURL, atomically: true, encoding: .utf8)
            logger.info("Quick exported to desktop: \(fileName)")
            return fileURL
        } catch {
            logger.error("Failed to write quick export: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - HTML Building

    private func buildHeader(title: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let now = dateFormatter.string(from: Date())

        return """
        <!DOCTYPE NETSCAPE-Bookmark-file-1>
        <!--
            This is an automatically generated file.
            It was exported from Plank Bookmark Manager
            on \(now).
        -->
        <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
        <TITLE>\(escapeHTML(title))</TITLE>
        <H1>\(escapeHTML(title))</H1>
        <DL><p>
        """
    }

    private func buildFooter() -> String {
        return "</DL><p>\n"
    }

    private func buildFolder(name: String, bookmarks: [Bookmark], addDate: Date) -> String {
        let dt = dateToNetscapeDate(addDate)
        var folder = "    <DT><H3 ADD_DATE=\"\(dt)\">\(escapeHTML(name))</H3>\n"
        folder += "    <DL><p>\n"

        for bookmark in bookmarks {
            folder += buildBookmarkEntry(bookmark)
        }

        folder += "    </DL><p>\n"
        return folder
    }

    private func buildBookmarkEntry(_ bookmark: Bookmark) -> String {
        let name = escapeHTML(bookmark.name)
        let url = escapeHTML(bookmark.url ?? "")
        let icon = escapeHTML(bookmark.icon.isEmpty ? "globe" : bookmark.icon)
        let addDate = dateToNetscapeDate(Date())

        return """
                <DT><A HREF="\(url)" ADD_DATE="\(addDate)" ICON="\(icon)">\(name)</A>\n
        """
    }

    // MARK: - Utilities

    /// Convert Date to Netscape-format timestamp (seconds since Unix epoch)
    private func dateToNetscapeDate(_ date: Date) -> Int {
        return Int(date.timeIntervalSince1970)
    }

    /// Escape special HTML characters
    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

// MARK: - CSV Exporter

/// Exports bookmarks to CSV format for spreadsheet import
final class CSVBookmarkExporter {
    static let shared = CSVBookmarkExporter()

    private init() {}

    func exportToCSV(bookmarks: [Bookmark]) -> String {
        var csv = "Name,URL,Type,Is Pinned,Link Status,Added\n"

        for bookmark in bookmarks {
            let name = escapeCSV(bookmark.name)
            let url = escapeCSV(bookmark.url ?? "")
            let type = bookmark.type.rawValue
            let isPinned = bookmark.isPinned ? "Yes" : "No"
            let linkStatus = bookmark.linkStatus.displayName
            let added = dateToISO(bookmark.id != nil ? Date() : Date())

            csv += "\(name),\(url),\(type),\(isPinned),\(linkStatus),\(added)\n"
        }

        return csv
    }

    func saveToFile(bookmarks: [Bookmark]) -> URL? {
        let csv = exportToCSV(bookmarks: bookmarks)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "Plank-Bookmarks.csv"
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return nil
        }

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSVExporter: Failed to write: \(error)")
            return nil
        }
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }

    private func dateToISO(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
}
