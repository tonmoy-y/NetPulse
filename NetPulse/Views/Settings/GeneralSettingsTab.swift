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
}
