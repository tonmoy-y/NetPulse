import AppKit

/// Main-actor isolated so it can call into `AppState` directly. That matters
/// for `applicationWillTerminate`, where hopping onto another queue would
/// mean the app exits before the work ever ran.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon; menu-bar-only app

        AppState.shared.start()

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleWillSleep), name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleDidWake), name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // menu-bar-only app: closing the Settings window must not quit the app
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.flushPendingWrites()
    }

    @objc private func handleWillSleep() {
        let state = AppState.shared
        state.trafficSampler.stop()
        state.latencyMonitor.stop()
        state.flushPendingWrites()
    }

    @objc private func handleDidWake() {
        let state = AppState.shared
        state.trafficSampler.start(interval: state.settings.refreshInterval.rawValue)
        state.interfaceMonitor.refresh()
        if state.settings.latency.isEnabled {
            state.latencyMonitor.start(host: state.settings.latency.resolvedHost, interval: state.settings.latency.intervalSeconds)
        }
    }
}
