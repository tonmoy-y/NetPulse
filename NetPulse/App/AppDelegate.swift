import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon; menu-bar-only app

        Task { @MainActor in
            AppState.shared.start()
        }

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

    @objc private func handleWillSleep() {
        Task { @MainActor in
            AppState.shared.trafficSampler.stop()
            AppState.shared.latencyMonitor.stop()
        }
    }

    @objc private func handleDidWake() {
        Task { @MainActor in
            let state = AppState.shared
            state.trafficSampler.start(interval: state.settings.refreshInterval.rawValue)
            state.interfaceMonitor.refresh()
            if state.settings.latency.isEnabled {
                state.latencyMonitor.start(host: state.settings.latency.resolvedHost, interval: state.settings.latency.intervalSeconds)
            }
        }
    }
}
