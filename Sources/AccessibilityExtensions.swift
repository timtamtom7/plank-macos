import SwiftUI
extension View {
    func accessibilityBookmarkLabel(name: String) -> some View {
        self.accessibilityLabel("Bookmark \(name)")
    }
}
