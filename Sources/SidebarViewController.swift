import AppKit
import SQLite

class SidebarViewController: NSViewController {

    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var addButton: NSButton!
    private var editButton: NSButton!
    private var isEditMode = false

    private var pinnedApps: [Bookmark] = []
    private var bookmarks: [Bookmark] = []

    var onClose: (() -> Void)?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 600))
        self.view.wantsLayer = true
        setupUI()
        loadData()
    }

    private func setupUI() {
        // Header
        let headerView = createHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Scroll view + table
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        tableView = NSTableView()
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = NSSize(width: 0, height: 4)
        tableView.rowHeight = 44
        tableView.selectionHighlightStyle = .none
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.draggingDestinationFeedbackStyle = .gap
        tableView.registerForDraggedTypes([.string])

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BookmarkColumn"))
        column.width = 300
        tableView.addTableColumn(column)

        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView

        // Footer
        let footerView = createFooterView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func createHeaderView() -> NSView {
        let container = NSView()
        container.wantsLayer = true

        let titleLabel = NSTextField(labelWithString: "PLANK")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        editButton = NSButton(image: NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")!, target: self, action: #selector(toggleEditMode))
        editButton.bezelStyle = .accessoryBarAction
        editButton.isBordered = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(editButton)

        let settingsButton = NSButton(image: NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")!, target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .accessoryBarAction
        settingsButton.isBordered = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(settingsButton)

        let closeButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")!, target: self, action: #selector(closeSidebar))
        closeButton.bezelStyle = .accessoryBarAction
        closeButton.isBordered = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Theme.padding),

            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Theme.padding),

            settingsButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            editButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8)
        ])

        return container
    }

    private func createFooterView() -> NSView {
        let container = NSView()
        container.wantsLayer = true

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)

        addButton = NSButton(image: NSImage(systemSymbolName: "plus", accessibilityDescription: "Add Bookmark")!, target: self, action: #selector(addBookmark))
        addButton.bezelStyle = .accessoryBarAction
        addButton.isBordered = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(addButton)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: container.topAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            addButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            addButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 28),
            addButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        return container
    }

    // MARK: - Data

    private func loadData() {
        pinnedApps = BookmarkStore.shared.getPinnedApps()
        bookmarks = BookmarkStore.shared.getBookmarks()
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func closeSidebar() {
        onClose?()
    }

    @objc private func toggleEditMode() {
        isEditMode.toggle()
        tableView.reloadData()
    }

    @objc private func openSettings() {
        // Placeholder for R2
    }

    @objc private func addBookmark() {
        showBookmarkSheet(bookmark: nil)
    }

    private func showBookmarkSheet(bookmark: Bookmark?) {
        let sheet = AddBookmarkSheet(bookmark: bookmark)
        sheet.onSave = { [weak self] newBookmark in
            if let existing = bookmark {
                var updated = existing
                updated.name = newBookmark.name
                updated.url = newBookmark.url
                updated.path = newBookmark.path
                updated.icon = newBookmark.icon
                updated.type = newBookmark.type
                updated.isPinned = newBookmark.isPinned
                BookmarkStore.shared.update(updated)
            } else {
                var toInsert = newBookmark
                toInsert.position = (self?.bookmarks.count ?? 0) + (self?.pinnedApps.count ?? 0)
                _ = BookmarkStore.shared.insert(toInsert)
            }
            self?.loadData()
        }
        presentAsSheet(sheet)
    }
}

// MARK: - NSTableViewDataSource

extension SidebarViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var total = 0
        if !pinnedApps.isEmpty { total += 1 + pinnedApps.count }
        if !bookmarks.isEmpty { total += 1 + bookmarks.count }
        return total
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let (section, index) = sectionAndIndex(for: row)

        if section == "pinnedApps" {
            if index == -1 {
                return makeSectionHeader("Pinned Apps")
            } else {
                return makeBookmarkRow(for: pinnedApps[index])
            }
        } else if section == "bookmarks" {
            if index == -1 {
                return makeSectionHeader("Bookmarks")
            } else {
                return makeBookmarkRow(for: bookmarks[index])
            }
        }
        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let (section, _) = sectionAndIndex(for: row)
        return section == "header" ? 28 : 44
    }

    private func sectionAndIndex(for row: Int) -> (String, Int) {
        var current = 0
        if !pinnedApps.isEmpty {
            if row == current { return ("header", -1) }
            current += 1
            if row < current + pinnedApps.count { return ("pinnedApps", row - current) }
            current += pinnedApps.count
        }
        if !bookmarks.isEmpty {
            if row == current { return ("header", -1) }
            current += 1
            if row < current + bookmarks.count { return ("bookmarks", row - current) }
            current += bookmarks.count
        }
        return ("", -1)
    }

    private func makeSectionHeader(_ title: String) -> NSView {
        let view = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.padding),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }

    private func makeBookmarkRow(for bookmark: Bookmark) -> NSView {
        let rowView = BookmarkRowView(bookmark: bookmark, isEditMode: isEditMode)
        rowView.onClick = { [weak self] in
            self?.handleClick(bookmark)
        }
        rowView.onEdit = { [weak self] in
            self?.showBookmarkSheet(bookmark: bookmark)
        }
        rowView.onDelete = { [weak self] in
            self?.confirmDelete(bookmark)
        }
        return rowView
    }

    private func handleClick(_ bookmark: Bookmark) {
        switch bookmark.type {
        case .weblink:
            if let urlStr = bookmark.url, let url = URL(string: urlStr) {
                NSWorkspace.shared.open(url)
            }
        case .folder:
            if let folderPath = bookmark.path {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderPath)
            }
        case .app:
            if let appPath = bookmark.path {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: appPath), configuration: NSWorkspace.OpenConfiguration())
            }
        }
    }

    private func confirmDelete(_ bookmark: Bookmark) {
        let alert = NSAlert()
        alert.messageText = "Delete \"\(bookmark.name)\"?"
        alert.informativeText = "This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let bid = bookmark.id {
                BookmarkStore.shared.delete(bid)
                loadData()
            }
        }
    }

    // MARK: - Drag & Drop

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let (section, index) = sectionAndIndex(for: row)
        if section == "header" { return nil }
        let bookmark: Bookmark = section == "pinnedApps" ? pinnedApps[index] : bookmarks[index]
        let item = NSPasteboardItem()
        item.setString("\(bookmark.id ?? 0)", forType: .string)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        tableView.setDropRow(row, dropOperation: .above)
        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
              let idString = item.string(forType: .string),
              let draggedId = Int64(idString) else { return false }

        let (targetSection, targetIndex) = sectionAndIndex(for: row)

        // Find and remove the dragged bookmark from its current list
        var allItems = pinnedApps + bookmarks
        guard let draggedIndex = allItems.firstIndex(where: { $0.id == draggedId }) else { return false }
        let draggedBookmark = allItems.remove(at: draggedIndex)

        // Insert at new position
        if targetSection == "pinnedApps" {
            var newPinned = pinnedApps
            newPinned.removeAll { $0.id == draggedId }
            let insertAt = targetIndex == -1 ? 0 : min(targetIndex, newPinned.count)
            newPinned.insert(draggedBookmark, at: insertAt)
            pinnedApps = newPinned
        } else {
            var newBookmarks = bookmarks
            newBookmarks.removeAll { $0.id == draggedId }
            let insertAt = targetIndex == -1 ? 0 : min(targetIndex, newBookmarks.count)
            newBookmarks.insert(draggedBookmark, at: insertAt)
            bookmarks = newBookmarks
        }

        // Persist new order
        var allReordered = pinnedApps + bookmarks
        for (i, var b) in allReordered.enumerated() {
            b.position = i
            BookmarkStore.shared.update(b)
        }

        loadData()
        return true
    }
}

// MARK: - NSTableViewDelegate

extension SidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

// MARK: - Add Bookmark Sheet

class AddBookmarkSheet: NSViewController {

    private var bookmark: Bookmark?
    private var nameField: NSTextField!
    private var urlField: NSTextField!
    private var pathField: NSTextField!
    private var typeSegment: NSSegmentedControl!
    private var iconField: NSTextField!
    private var pinnedCheckbox: NSButton!

    var onSave: ((Bookmark) -> Void)?

    init(bookmark: Bookmark?) {
        self.bookmark = bookmark
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 320))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let b = bookmark {
            populate(b)
        }
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Type selector
        typeSegment = NSSegmentedControl(labels: ["Web Link", "Folder", "App"], trackingMode: .selectOne, target: self, action: #selector(typeChanged))
        typeSegment.selectedSegment = 0
        stack.addArrangedSubview(typeSegment)

        // Name
        nameField = createLabeledField("Name:", placeholder: "My Bookmark")
        stack.addArrangedSubview(nameField)

        // URL
        urlField = createLabeledField("URL:", placeholder: "https://example.com")
        stack.addArrangedSubview(urlField)

        // Path
        pathField = createLabeledField("Path:", placeholder: "")
        let browseButton = NSButton(title: "Browse…", target: self, action: #selector(browsePath))
        browseButton.bezelStyle = .rounded
        stack.addArrangedSubview(pathField.superview!)
        pathField.superview?.addSubview(browseButton)
        browseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browseButton.trailingAnchor.constraint(equalTo: pathField.superview!.trailingAnchor),
            browseButton.centerYAnchor.constraint(equalTo: pathField.centerYAnchor)
        ])

        // Icon
        iconField = createLabeledField("Icon (SF Symbol):", placeholder: "link")
        stack.addArrangedSubview(iconField)

        // Pinned
        pinnedCheckbox = NSButton(checkboxWithTitle: "Pin to top (Pinned Apps)", target: nil, action: nil)
        stack.addArrangedSubview(pinnedCheckbox)

        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(spacer)

        // Buttons
        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fill

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        buttonRow.addArrangedSubview(NSView())
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(saveButton)
        stack.addArrangedSubview(buttonRow)

        updateFieldsVisibility()
    }

    private func createLabeledField(_ label: String, placeholder: String) -> NSTextField {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let labelView = NSTextField(labelWithString: label)
        labelView.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        labelView.textColor = .secondaryLabelColor
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)

        let field = NSTextField()
        field.placeholderString = placeholder
        field.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(field)

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            field.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            field.heightAnchor.constraint(equalToConstant: 24)
        ])

        return field
    }

    @objc private func typeChanged() {
        updateFieldsVisibility()
    }

    private func updateFieldsVisibility() {
        urlField.isHidden = typeSegment.selectedSegment != 0
        pathField.isHidden = typeSegment.selectedSegment == 0
        if let parent = pathField.superview {
            parent.subviews.first { $0 != pathField && $0 != parent.subviews.last }?.isHidden = typeSegment.selectedSegment == 0
        }

        switch typeSegment.selectedSegment {
        case 0:
            iconField.stringValue = "globe"
            pathField.stringValue = ""
        case 1:
            iconField.stringValue = "folder.fill"
            urlField.stringValue = ""
        case 2:
            iconField.stringValue = "app.fill"
            urlField.stringValue = ""
        default:
            break
        }
    }

    @objc private func browsePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if typeSegment.selectedSegment == 2 {
            panel.allowedContentTypes = [.application]
        }
        if panel.runModal() == .OK, let url = panel.url {
            pathField.stringValue = url.path
            if nameField.stringValue.isEmpty {
                nameField.stringValue = url.deletingPathExtension().lastPathComponent
            }
        }
    }

    private func populate(_ bookmark: Bookmark) {
        nameField.stringValue = bookmark.name
        urlField.stringValue = bookmark.url ?? ""
        pathField.stringValue = bookmark.path ?? ""
        iconField.stringValue = bookmark.icon
        pinnedCheckbox.state = bookmark.isPinned ? .on : .off

        switch bookmark.type {
        case .weblink: typeSegment.selectedSegment = 0
        case .folder: typeSegment.selectedSegment = 1
        case .app: typeSegment.selectedSegment = 2
        }
        updateFieldsVisibility()
    }

    @objc private func cancel() {
        dismiss(nil)
    }

    @objc private func save() {
        let type: BookmarkType
        switch typeSegment.selectedSegment {
        case 0: type = .weblink
        case 1: type = .folder
        case 2: type = .app
        default: type = .weblink
        }

        let newBookmark = Bookmark(
            name: nameField.stringValue,
            url: urlField.stringValue.isEmpty ? nil : urlField.stringValue,
            path: pathField.stringValue.isEmpty ? nil : pathField.stringValue,
            icon: iconField.stringValue.isEmpty ? "link" : iconField.stringValue,
            position: bookmark?.position ?? 0,
            type: type,
            isPinned: pinnedCheckbox.state == .on
        )
        onSave?(newBookmark)
        dismiss(nil)
    }
}
