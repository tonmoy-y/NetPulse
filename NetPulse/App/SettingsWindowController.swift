import SwiftUI
import AppKit

/// Owns the Settings window directly with AppKit instead of going through
/// SwiftUI's `Settings` scene. The `Settings` scene has a long-standing,
/// well-documented limitation: it frequently ignores `.frame(minWidth:...)`
/// resizability hints entirely and locks the window to a fixed size
/// regardless — which is exactly the "window isn't resizable" bug that kept
/// coming back no matter what frame modifiers were tried. Managing the
/// window ourselves means resizability is a plain, explicit `styleMask`
/// flag we control directly, not something left to SwiftUI scene behavior.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private convenience init() {
        let hosting = NSHostingController(
            rootView: SettingsView()
                .environmentObject(AppState.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        // NSHostingController's default sizingOptions include tracking its
        // SwiftUI content's own "ideal size" and resizing the window to
        // match it — every time the content's ideal size changed (e.g.
        // switching to a tab with more or less content), the window would
        // silently snap back to that size, undoing whatever size the user
        // had just dragged it to. Turning that off is what actually makes
        // manual resizing stick.
        hosting.sizingOptions = []

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = "NetPulse Settings"
        // Match the native "Preferences pane" look SwiftUI's Settings scene
        // gets for free (transparent, unified title bar) — a plain NSWindow
        // otherwise renders as a generic opaque-titlebar window instead.
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .preference
        window.setContentSize(NSSize(width: 460, height: 420))
        window.minSize = NSSize(width: 460, height: 420)
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
        window.delegate = self
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
