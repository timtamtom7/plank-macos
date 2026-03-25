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
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: dragHandle.leadingAnchor, constant: -8),

            // Subtitle
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: dragHandle.leadingAnchor, constant: -8),

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
