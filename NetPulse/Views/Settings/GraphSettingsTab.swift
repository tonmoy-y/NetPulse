import SwiftUI
import NetPulseCore

struct GraphSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Time Range") {
                Picker("Default window", selection: $appState.settings.graphTimeWindow) {
                    ForEach(GraphTimeWindow.allCases) { window in
                        Text(window.label).tag(window)
                    }
                }
            }

            Section("Series") {
                Toggle("Show download line", isOn: $appState.settings.showDownloadInGraph)
                Toggle("Show upload line", isOn: $appState.settings.showUploadInGraph)
            }

            Section {
                Text("The graph samples at your configured refresh interval and keeps up to one hour of history in memory. Nothing older is retained once the window rolls past it.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }
        }
        .formStyle(.grouped)
    }
}
