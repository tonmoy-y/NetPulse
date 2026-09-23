import SwiftUI

@main
struct NetPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(appState)
                .frame(width: 360)
        } label: {
            MenuBarLabelView()
                .environmentObject(appState.menuBarModel)
        }
        .menuBarExtraStyle(.window)

        // No SwiftUI `Settings` scene here — SettingsWindowController owns
        // that window directly with AppKit so it's genuinely resizable
        // (see its doc comment for why).
    }
}
