import AppKit

extension NSView {
    /// Sets accessibility properties for an NSView
    func setAccessibilityInfo(label: String, role: NSAccessibility.Role? = nil, hint: String? = nil) {
        self.setAccessibilityLabel(label)
        if let role = role {
            self.setAccessibilityRole(role)
        }
        if let hint = hint {
            self.setAccessibilityHelp(hint)
        }
    }
}

extension NSButton {
    /// Configures a button with proper accessibility attributes
    func configureAccessibility(label: String, hint: String? = nil) {
        self.setAccessibilityLabel(label)
        self.setAccessibilityRole(.button)
        if let hint = hint {
            self.setAccessibilityHelp(hint)
        }
    }
}
