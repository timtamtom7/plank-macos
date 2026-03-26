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
            symbolName = bookmark.icon.isEmpty ? "globe" : bookmark.icon
        case .folder:
            symbolName = bookmark.icon.isEmpty ? "folder.fill" : bookmark.icon
        case .app:
            symbolName = bookmark.icon.isEmpty ? "app.fill" : bookmark.icon
        }
        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: bookmark.name)
        iconView.contentTintColor = tintColorForBookmark()
        addSubview(iconView)

        // For apps, try to load the actual icon
        if bookmark.type == .app, let path = bookmark.path {
            iconView.image = NSWorkspace.shared.icon(forFile: path)
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
        editButton = NSButton(image: NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")!, target: self, action: #selector(editTapped))
        editButton.bezelStyle = .accessoryBarAction
        editButton.isBordered = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.isHidden = !isEditMode
        addSubview(editButton)

        // Delete button
        deleteButton = NSButton(image: NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")!, target: self, action: #selector(deleteTapped))
        deleteButton.bezelStyle = .accessoryBarAction
        deleteButton.isBordered = false
        deleteButton.contentTintColor = .systemRed
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = !isEditMode
        addSubview(deleteButton)

        // Drag handle
        dragHandle = NSImageView()
        dragHandle.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "Drag")
        dragHandle.contentTintColor = Theme.tertiaryTextColor
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.isHidden = !isEditMode
        addSubview(dragHandle)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.padding),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
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
            editButton.widthAnchor.constraint(equalToConstant: 20),
            editButton.heightAnchor.constraint(equalToConstant: 20),

            // Delete button
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.padding),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20),

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
        case .valid: return NSColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0) // #10B981 Success
        case .broken: return NSColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0) // #EF4444 Destructive
        case .redirected: return NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0) // #F59E0B Warning
        case .timeout: return NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0) // #F59E0B Warning
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
