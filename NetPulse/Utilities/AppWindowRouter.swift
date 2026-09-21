import AppKit

/// Opens the SwiftUI `Settings` scene from AppKit-driven call sites (the
/// popover's footer button). `showSettingsWindow:` is the action SwiftUI
/// registers on `NSApplication` for its `Settings` scene and is the
/// standard way to trigger it outside of the automatic ⌘, menu item.
enum AppWindowRouter {
    static func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
