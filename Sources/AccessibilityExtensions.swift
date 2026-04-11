import AppKit

extension NSView {
    /// Sets accessibility properties for an NSView
    func setAccessibilityInfo(label: String, role: NSAccessibility.Role? = nil, hint: String? = nil) {
        self.accessibilityLabel = label
        if let role = role {
            self.accessibilityRole = role
        }
        if let hint = hint {
            self.accessibilityHelp = hint
        }
    }
}

extension NSButton {
    /// Configures a button with proper accessibility attributes
    func configureAccessibility(label: String, hint: String? = nil) {
        self.accessibilityLabel = label
        self.accessibilityRole = .button
        if let hint = hint {
            self.accessibilityHelp = hint
        }
    }
}
