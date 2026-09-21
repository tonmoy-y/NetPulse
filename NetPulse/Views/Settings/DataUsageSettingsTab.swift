import SwiftUI
import NetPulseCore

struct DataUsageSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section("Current Usage") {
                usageRow("Today", appState.dataUsageStore.today)
                usageRow("This week", appState.dataUsageStore.thisWeek)
                usageRow("This month", appState.dataUsageStore.thisMonth)
            }

            Section {
                Toggle("Persist usage across launches", isOn: $appState.settings.dataUsage.persistAcrossLaunches)

                Stepper(value: $appState.settings.dataUsage.retentionDays, in: 7...365, step: 1) {
                    Text("Retention: \(appState.settings.dataUsage.retentionDays) days")
                }
            }

            Section {
                Text("Daily totals are derived by summing throughput samples taken at your refresh interval. This is an estimate of observed traffic on the monitored interface, not a carrier-grade accounting figure.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section {
                Button("Reset Data Usage Statistics…") { showResetConfirmation = true }
                    .foregroundStyle(Color.netPulseError)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset all recorded data usage?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { appState.dataUsageStore.reset() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func usageRow(_ label: String, _ totals: DataUsageTotals) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(ByteFormatter.formatBytes(Double(totals.downloadedBytes)))
                .foregroundStyle(Color.netPulseDownload)
            Text(ByteFormatter.formatBytes(Double(totals.uploadedBytes)))
                .foregroundStyle(Color.netPulseUpload)
        }
        .font(.netPulseBody)
    }
}
