import AppKit
import SQLite

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var sidebarPanel: NSPanel!
    private var sidebarViewController: SidebarViewController!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        BookmarkStore.shared.initialize()
        PlankState.shared.bookmarks = BookmarkStore.shared.getAll()
        setupStatusItem()
        setupSidebarPanel()
        setupPopover()
        setupMainMenu()
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Plank", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Check All Links…", action: #selector(checkAllLinksFromMenu), keyEquivalent: "k"))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Plank", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "New Bookmark…", action: #selector(newBookmarkFromMenu), keyEquivalent: "b"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Export as HTML…", action: #selector(exportHTMLFromMenu), keyEquivalent: "e"))
        fileMenu.addItem(NSMenuItem(title: "Export as CSV…", action: #selector(exportCSVFromMenu), keyEquivalent: ""))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Sidebar", action: #selector(closeSidebarFromMenu), keyEquivalent: "w"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(NSMenuItem(title: "Toggle Sidebar", action: #selector(toggleSidebarFromMenu), keyEquivalent: "s"))
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Plank"
        alert.informativeText = "A native macOS bookmark manager.\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func newBookmarkFromMenu() {
        toggleSidebar()
        // Brief delay to let the sidebar appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.sidebarViewController.performSelector(onMainThread: NSSelectorFromString("addBookmark"), with: nil, waitUntilDone: false)
        }
    }

    @objc private func exportHTMLFromMenu() {
        let bookmarks = BookmarkStore.shared.getAll()
        if let url = HTMLBookmarkExporter.shared.saveToFile(bookmarks: bookmarks) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc private func exportCSVFromMenu() {
        let bookmarks = BookmarkStore.shared.getAll()
        if let url = CSVBookmarkExporter.shared.saveToFile(bookmarks: bookmarks) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc private func checkAllLinksFromMenu() {
        toggleSidebar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.sidebarViewController.performSelector(onMainThread: NSSelectorFromString("checkLinks"), with: nil, waitUntilDone: false)
        }
    }

    @objc private func closeSidebarFromMenu() {
        sidebarPanel.orderOut(nil)
    }

    @objc private func toggleSidebarFromMenu() {
        toggleSidebar()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.1x2", accessibilityDescription: "Plank")
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        if let event = NSApp.currentEvent, event.modifierFlags.contains(.option) {
            // Option-click: toggle sidebar
            toggleSidebar()
        } else {
            // Normal click: show popover
            togglePopover()
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.animates = true

        let vc = NSViewController()
        vc.view = createPopoverContentView()
        popover.contentViewController = vc
    }

    private func createPopoverContentView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        container.wantsLayer = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        let titleLabel = NSTextField(labelWithString: "PLANK")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .labelColor
        stack.addArrangedSubview(titleLabel)

        let subtitleLabel = NSTextField(labelWithString: "Your floating sidebar")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitleLabel)

        let openButton = NSButton(title: "Open Sidebar", target: self, action: #selector(openSidebar))
        openButton.bezelStyle = .rounded
        openButton.controlSize = .large
        stack.addArrangedSubview(openButton)

        let tipLabel = NSTextField(labelWithString: "Option-click the menu bar icon to toggle the sidebar directly.")
        tipLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        tipLabel.textColor = .tertiaryLabelColor
        tipLabel.alignment = .center
        tipLabel.maximumNumberOfLines = 3
        stack.addArrangedSubview(tipLabel)

        return container
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    // MARK: - Sidebar Panel

    private func setupSidebarPanel() {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelWidth: CGFloat = 320
        let panelHeight = screenFrame.height
        let panelX = screenFrame.maxX - panelWidth
        let panelY = screenFrame.minY

        let panelRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

        sidebarPanel = NSPanel(
            contentRect: panelRect,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        sidebarPanel.title = "PLANK"
        sidebarPanel.level = .floating
        sidebarPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        sidebarPanel.isMovableByWindowBackground = true
        sidebarPanel.titlebarAppearsTransparent = false
        sidebarPanel.titleVisibility = .visible
        sidebarPanel.minSize = NSSize(width: 280, height: 300)
        sidebarPanel.maxSize = NSSize(width: 400, height: 2000)
        sidebarPanel.backgroundColor = NSColor.windowBackgroundColor
        sidebarPanel.isReleasedWhenClosed = false

        sidebarViewController = SidebarViewController()
        sidebarViewController.onClose = { [weak self] in
            self?.sidebarPanel.orderOut(nil)
        }
        sidebarPanel.contentViewController = sidebarViewController
        sidebarPanel.initialFirstResponder = sidebarViewController.view
    }

    private func toggleSidebar() {
        if sidebarPanel.isVisible {
            sidebarPanel.orderOut(nil)
        } else {
            repositionSidebar()
            sidebarPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func openSidebar() {
        popover.performClose(nil)
        toggleSidebar()
    }

    private func repositionSidebar() {
        guard let screenFrame = NSScreen.main?.visibleFrame else { return }
        let panelWidth = sidebarPanel.frame.width
        let panelX = screenFrame.maxX - panelWidth
        let panelY = screenFrame.minY
        sidebarPanel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - PlankState

@MainActor
final class PlankState {
    static let shared = PlankState()

    var bookmarks: [Bookmark] = []

    private init() {}

    func openBookmark(_ bookmark: Bookmark) {
        if let urlString = bookmark.url, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else if let path = bookmark.path {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}

