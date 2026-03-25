import AppKit

enum Theme {

    // MARK: - Colors

    static var backgroundColor: NSColor {
        return NSColor.windowBackgroundColor
    }

    static var secondaryBackground: NSColor {
        return NSColor.controlBackgroundColor
    }

    static var accentColor: NSColor {
        return NSColor.controlAccentColor
    }

    static var textColor: NSColor {
        return NSColor.labelColor
    }

    static var secondaryTextColor: NSColor {
        return NSColor.secondaryLabelColor
    }

    static var tertiaryTextColor: NSColor {
        return NSColor.tertiaryLabelColor
    }

    static var separatorColor: NSColor {
        return NSColor.separatorColor
    }

    static var rowHoverColor: NSColor {
        return NSColor.selectedContentBackgroundColor.withAlphaComponent(0.1)
    }

    // MARK: - Spacing

    static let padding: CGFloat = 12
    static let smallPadding: CGFloat = 6
    static let largePadding: CGFloat = 20

    // MARK: - Corner Radius

    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 4

    // MARK: - Font

    static var titleFont: NSFont {
        return NSFont.systemFont(ofSize: 14, weight: .semibold)
    }

    static var bodyFont: NSFont {
        return NSFont.systemFont(ofSize: 13, weight: .regular)
    }

    static var captionFont: NSFont {
        return NSFont.systemFont(ofSize: 11, weight: .regular)
    }

    // MARK: - SF Symbols

    enum Symbol {
        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let folder = "folder"
        static let weblink = "link"
        static let app = "app"
        static let dragHandle = "line.3.horizontal"
        static let pin = "pin"
        static let chevronRight = "chevron.right"
        static let settings = "gear"
        static let close = "xmark"
        static let minimize = "minus"
        static let folderOpen = "folder.fill"
        static let globe = "globe"
        static let appDefault = "app.fill"
    }
}
