import SwiftUI
import AppKit

private extension NSToolbarItem.Identifier {
    static func settings(_ tab: SettingsTab) -> NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("com.netpulse.settings.\(tab.rawValue)")
    }
}

/// Owns the Settings window directly with AppKit instead of going through
/// SwiftUI's `Settings` scene, and drives tab switching with a real
/// NSToolbar instead of SwiftUI's TabView. Two SwiftUI-scene limitations
/// forced this:
/// - The `Settings` scene frequently ignores `.frame(minWidth:...)`
///   resizability hints and locks the window to a fixed size.
/// - TabView's own tab bar has no native overflow handling outside of an
///   actual `Settings` scene — with 10 tabs, tabs that didn't fit were just
///   truncated with no way to reach them, not tucked into an overflow menu.
/// A plain NSToolbar gets AppKit's real overflow chevron for free, the same
/// mechanism System Settings itself uses, regardless of window width.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    static let shared = SettingsWindowController()

    private var tabSelection: SettingsTabSelection!

    private convenience init() {
        let tabSelection = SettingsTabSelection()

        let hosting = NSHostingController(
            rootView: SettingsView()
                .environmentObject(AppState.shared)
                .environmentObject(tabSelection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        // NSHostingController's default sizingOptions include tracking its
        // SwiftUI content's own "ideal size" and resizing the window to
        // match it — the window would silently snap back to that size every
        // time content changed, undoing any manual resize.
        hosting.sizingOptions = []

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = "NetPulse Settings"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .preference
        window.setContentSize(NSSize(width: 460, height: 420))
        window.minSize = NSSize(width: 420, height: 360)
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
        self.tabSelection = tabSelection
        window.delegate = self

        let toolbar = NSToolbar(identifier: "com.netpulse.settings.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = .settings(.general)
        window.toolbar = toolbar
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func selectTab(_ sender: NSToolbarItem) {
        let rawTab = sender.itemIdentifier.rawValue.replacingOccurrences(of: "com.netpulse.settings.", with: "")
        guard let tab = SettingsTab(rawValue: rawTab) else { return }
        tabSelection.selected = tab
        window?.toolbar?.selectedItemIdentifier = sender.itemIdentifier
    }

    // MARK: - NSToolbarDelegate

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map { .settings($0) }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let rawTab = itemIdentifier.rawValue.replacingOccurrences(of: "com.netpulse.settings.", with: "")
        guard let tab = SettingsTab(rawValue: rawTab) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.title
        item.image = NSImage(systemSymbolName: tab.systemImage, accessibilityDescription: tab.title)
        item.target = self
        item.action = #selector(selectTab(_:))
        return item
    }
}
