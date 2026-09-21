import SwiftUI
import NetPulseCore

/// The actual content rendered in the macOS menu bar. Kept intentionally tiny
/// — a couple of monospaced numbers and optional arrows, never icons for
/// CPU/RAM/battery. Re-renders only when a new sample arrives.
struct MenuBarLabelView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let text = MenuBarFormatter.format(
            downloadBps: appState.trafficStatistics.currentDownloadBps,
            uploadBps: appState.trafficStatistics.currentUploadBps,
            options: appState.settings.menuBar
        )

        HStack(spacing: 4) {
            if appState.settings.showConnectionStateInMenuBar {
                statusDot
            }
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        switch appState.networkQuality {
        case .offline:
            Circle().fill(Color.netPulseError).frame(width: 6, height: 6)
        case .poor:
            Circle().fill(Color.netPulseWarning).frame(width: 6, height: 6)
        default:
            EmptyView() // normal/good/excellent stays silent — no visual noise
        }
    }
}
