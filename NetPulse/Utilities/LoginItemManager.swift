import Foundation
import ServiceManagement

/// Wraps the modern `SMAppService` login-item API (macOS 13+). No private
/// APIs, no helper-tool bundle tricks.
enum LoginItemManager {
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("NetPulse: failed to update login item state — \(error.localizedDescription)")
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
