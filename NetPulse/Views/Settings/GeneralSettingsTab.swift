import SwiftUI
import NetPulseCore

struct GeneralSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $appState.settings.launchAtLogin)
                Toggle("Start hidden", isOn: $appState.settings.startHidden)
                Toggle("Pause monitoring", isOn: $appState.settings.isMonitoringPaused)
            }

            Section("Update Interval") {
                Picker("Refresh every", selection: $appState.settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                Text("Lower intervals update faster but use slightly more CPU. 500 ms is a good default.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section("Updates") {
                Toggle("Automatically check for updates on launch", isOn: $appState.settings.checkForUpdatesAutomatically)
                updateStatusRow
                Text("Checks GitHub Releases for a newer NetPulse version — a single anonymous request, no analytics or identifying data. It only tells you a new version exists; it never downloads or installs anything automatically.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section {
                Button("Reset All Settings…") { showResetConfirmation = true }
                    .foregroundStyle(Color.netPulseError)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset all NetPulse settings to their defaults?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { appState.resetAllSettings() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var updateStatusRow: some View {
        switch appState.updateChecker.state {
        case .idle:
            Button("Check for Updates") { appState.updateChecker.checkForUpdates() }

        case .checking:
            HStack {
                ProgressView().controlSize(.small)
                Text("Checking for updates…").font(.netPulseCaption)
            }

        case .upToDate:
            HStack {
                Text("You're up to date.").font(.netPulseCaption).foregroundStyle(Color.netPulseSuccess)
                Spacer()
                Button("Check Again") { appState.updateChecker.checkForUpdates() }
            }

        case .updateAvailable(let version, let url):
            HStack {
                Text("\(version) is available.").font(.netPulseCaption).foregroundStyle(Color.netPulsePrimary)
                Spacer()
                Link("View Release", destination: url)
            }

        case .failed(let message):
            HStack {
                Text(message).font(.netPulseCaption).foregroundStyle(Color.netPulseTextMuted)
                Spacer()
                Button("Retry") { appState.updateChecker.checkForUpdates() }
            }
        }
    }
}
