import SwiftUI

struct AdvancedSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Connection History") {
                Button("Clear Connection History") {
                    appState.connectionHistoryStore.clear()
                }
            }

            Section("Diagnostics") {
                LabeledContent("Sampled interface", value: appState.interfaceMonitor.primaryInterface?.bsdName ?? "—")
                LabeledContent("Retained graph samples", value: "\(appState.trafficSampler.recentSamples.count)")
            }
        }
        .formStyle(.grouped)
    }
}
