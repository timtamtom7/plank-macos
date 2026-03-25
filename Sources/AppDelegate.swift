import AppKit
import SQLite

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var sidebarPanel: NSPanel!
    private var sidebarViewController: SidebarViewController!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        BookmarkStore.shared.initialize()
        setupStatusItem()
        setupSidebarPanel()
        setupPopover()
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
