import AppKit

class BookmarkRowView: NSView {

    private let bookmark: Bookmark
    private let isEditMode: Bool

    var onClick: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var iconView: NSImageView!
    private var nameLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var statusIconView: NSImageView!
    private var editButton: NSButton!
    private var deleteButton: NSButton!
    private var dragHandle: NSImageView!
    private var trackingArea: NSTrackingArea?

    private static var iconCache: [String: NSImage] = [:]

    init(bookmark: Bookmark, isEditMode: Bool) {
        self.bookmark = bookmark
        self.isEditMode = isEditMode
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = Theme.smallCornerRadius

        // Icon
        iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        let symbolName: String
        switch bookmark.type {
        case .weblink:
            symbolName = bookmark.icon.isEmpty ? Theme.Symbol.globe : bookmark.icon
        case .folder:
            symbolName = bookmark.icon.isEmpty ? Theme.Symbol.folderOpen : bookmark.icon
        case .app:
            symbolName = bookmark.icon.isEmpty ? Theme.Symbol.appDefault : bookmark.icon
        }
        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: bookmark.name)
        iconView.contentTintColor = tintColorForBookmark()
        addSubview(iconView)

        // For apps, load icon from cache or disk
        if bookmark.type == .app, let path = bookmark.path {
            if let cached = BookmarkRowView.iconCache[path] {
                iconView.image = cached
            } else {
                let icon = NSWorkspace.shared.icon(forFile: path)
                BookmarkRowView.iconCache[path] = icon
                iconView.image = icon
            }
        }

        // Name
        nameLabel = NSTextField(labelWithString: bookmark.name)
        nameLabel.font = Theme.bodyFont
        nameLabel.textColor = Theme.textColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Subtitle
        subtitleLabel = NSTextField(labelWithString: subtitleText())
        subtitleLabel.font = Theme.captionFont
        subtitleLabel.textColor = Theme.tertiaryTextColor
        subtitleLabel.lineBreakMode = .byTruncatingMiddle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        // Link status indicator (only for weblinks with a known status)
        statusIconView = NSImageView()
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        statusIconView.imageScaling = .scaleProportionallyUpOrDown
        statusIconView.isHidden = bookmark.type != .weblink || bookmark.linkStatus == .unknown
        if let statusImg = linkStatusImage() {
            statusIconView.image = statusImg
            statusIconView.contentTintColor = linkStatusColor()
            statusIconView.toolTip = bookmark.linkStatus.displayName
        }
        addSubview(statusIconView)

        // Edit button
        editButton = NSButton(image: NSImage(systemSymbolName: Theme.Symbol.edit, accessibilityDescription: "Edit")!, target: self, action: #selector(editTapped))
        editButton.bezelStyle = .accessoryBarAction
        editButton.isBordered = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.isHidden = !isEditMode
        editButton.accessibilityLabel = "Edit bookmark"
        editButton.accessibilityRole = .button
        addSubview(editButton)

        // Delete button
        deleteButton = NSButton(image: NSImage(systemSymbolName: Theme.Symbol.delete, accessibilityDescription: "Delete")!, target: self, action: #selector(deleteTapped))
        deleteButton.bezelStyle = .accessoryBarAction
        deleteButton.isBordered = false
        deleteButton.contentTintColor = .systemRed
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = !isEditMode
        deleteButton.accessibilityLabel = "Delete bookmark"
        deleteButton.accessibilityRole = .button
        addSubview(deleteButton)

        // Drag handle
        dragHandle = NSImageView()
        dragHandle.image = NSImage(systemSymbolName: Theme.Symbol.dragHandle, accessibilityDescription: "Drag")
        dragHandle.contentTintColor = Theme.tertiaryTextColor
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.isHidden = !isEditMode
        addSubview(dragHandle)

        setupConstraints()
    }

    private func setupConstraints() {
        let iconSize = Theme.iconSize
        let iconTextSpacing = Theme.iconTextSpacing
        let smallButtonSize = Theme.smallButtonSize

        NSLayoutConstraint.activate([
            // Icon
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.padding),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: iconTextSpacing),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIconView.leadingAnchor, constant: -4),

            // Subtitle
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: dragHandle.leadingAnchor, constant: -8),

            // Status icon (appears to the left of subtitle end)
            statusIconView.trailingAnchor.constraint(equalTo: dragHandle.leadingAnchor, constant: -4),
            statusIconView.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            statusIconView.widthAnchor.constraint(equalToConstant: 12),
            statusIconView.heightAnchor.constraint(equalToConstant: 12),

            // Edit button
            editButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -4),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: smallButtonSize),
            editButton.heightAnchor.constraint(equalToConstant: smallButtonSize),

            // Delete button
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.padding),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: smallButtonSize),
            deleteButton.heightAnchor.constraint(equalToConstant: smallButtonSize),

            // Drag handle
            dragHandle.trailingAnchor.constraint(equalTo: isEditMode ? editButton.leadingAnchor : trailingAnchor, constant: isEditMode ? -8 : 0),
            dragHandle.centerYAnchor.constraint(equalTo: centerYAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 16),
            dragHandle.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func tintColorForBookmark() -> NSColor {
        switch bookmark.type {
        case .weblink: return .systemBlue
        case .folder: return .systemYellow
        case .app: return .controlAccentColor
        }
    }

    private func subtitleText() -> String {
        switch bookmark.type {
        case .weblink: return bookmark.url ?? ""
        case .folder: return bookmark.path ?? "No path"
        case .app: return bookmark.path?.components(separatedBy: "/").last ?? "No path"
        }
    }

    private func linkStatusImage() -> NSImage? {
        switch bookmark.linkStatus {
        case .valid:
            return NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Link OK")
        case .broken:
            return NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Broken link")
        case .redirected:
            return NSImage(systemSymbolName: "arrow.uturn.right.circle.fill", accessibilityDescription: "Redirected")
        case .timeout:
            return NSImage(systemSymbolName: "clock.badge.exclamationmark", accessibilityDescription: "Timeout")
        case .checking:
            return NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Checking")
        case .unknown:
            return nil
        }
    }

    private func linkStatusColor() -> NSColor {
        switch bookmark.linkStatus {
        case .valid: return Theme.linkValidColor
        case .broken: return Theme.linkBrokenColor
        case .redirected: return Theme.linkWarningColor
        case .timeout: return Theme.linkWarningColor
        case .checking: return .secondaryLabelColor
        case .unknown: return .clear
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        layer?.backgroundColor = Theme.rowHoverColor.cgColor
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        layer?.backgroundColor = nil
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onClick?()
    }

    @objc private func editTapped() {
        onEdit?()
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}
