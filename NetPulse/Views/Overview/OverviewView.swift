import SwiftUI
import NetPulseCore

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                MetricTile(label: "DOWNLOAD", value: rate(appState.trafficStatistics.currentDownloadBps), accent: .netPulseDownload, arrow: "arrow.down")
                MetricTile(label: "UPLOAD", value: rate(appState.trafficStatistics.currentUploadBps), accent: .netPulseUpload, arrow: "arrow.up")
            }

            VStack(spacing: 0) {
                InfoRow(label: "Interface", value: appState.interfaceMonitor.primaryInterface?.displayName ?? "None detected")
                Divider()
                InfoRow(label: "Connection", value: appState.interfaceMonitor.isConnected ? "Connected" : "Disconnected")
                Divider()
                InfoRow(label: "Latency", value: latencyText)
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.netPulseBorder.opacity(0.25)))

            VStack(alignment: .leading, spacing: 6) {
                Text("DATA USAGE TODAY")
                    .font(.netPulseSectionTitle)
                    .foregroundStyle(Color.netPulseTextSecondary)
                HStack {
                    Label(ByteFormatter.formatBytes(Double(appState.dataUsageStore.today.downloadedBytes)), systemImage: "arrow.down")
                        .foregroundStyle(Color.netPulseDownload)
                    Spacer()
                    Label(ByteFormatter.formatBytes(Double(appState.dataUsageStore.today.uploadedBytes)), systemImage: "arrow.up")
                        .foregroundStyle(Color.netPulseUpload)
                }
                .font(.netPulseBody)
                Text("Estimated from observed interface counters, not carrier billing data.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }
        }
        .padding(14)
    }

    private func rate(_ bps: Double) -> String {
        ByteFormatter.formatRate(bytesPerSecond: bps, decimalPlaces: appState.settings.menuBar.decimalPlaces)
    }

    private var latencyText: String {
        guard appState.settings.latency.isEnabled else { return "Disabled" }
        guard let current = appState.latencyStatistics.current else { return "—" }
        return "\(Int(current)) ms"
    }
}

private struct MetricTile: View {
    let label: String
    let value: String
    let accent: Color
    let arrow: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: arrow).font(.system(size: 10, weight: .bold))
                Text(label).font(.netPulseMetricLabel)
            }
            .foregroundStyle(accent)

            Text(value)
                .font(.netPulseMetricValue)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.08)))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.netPulseBody).foregroundStyle(Color.netPulseTextSecondary)
            Spacer()
            Text(value).font(.netPulseBody)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
