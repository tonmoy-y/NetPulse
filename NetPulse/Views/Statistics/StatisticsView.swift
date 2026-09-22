import SwiftUI
import NetPulseCore

struct StatisticsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            trafficSection
            Divider()
            dataUsageSection
            Divider()
            latencySection
            Divider()
            connectionSection
            Divider()
            speedTestSection
        }
        .padding(14)
    }

    private var trafficSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Traffic")
            let s = appState.trafficStatistics
            StatRow("Average", down: rate(s.averageDownloadBps), up: rate(s.averageUploadBps))
            StatRow("Peak", down: rate(s.peakDownloadBps), up: rate(s.peakUploadBps))
            StatRow("Session", down: bytes(s.sessionDownloadedBytes), up: bytes(s.sessionUploadedBytes))
            StatRow("Lifetime total", down: bytes(s.totalDownloadedBytes), up: bytes(s.totalUploadedBytes))
        }
    }

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Data Usage")
            StatRow("Today", down: bytes(appState.dataUsageStore.today.downloadedBytes), up: bytes(appState.dataUsageStore.today.uploadedBytes))
            StatRow("Last 7 days", down: bytes(appState.dataUsageStore.thisWeek.downloadedBytes), up: bytes(appState.dataUsageStore.thisWeek.uploadedBytes))
            StatRow("Last 30 days", down: bytes(appState.dataUsageStore.thisMonth.downloadedBytes), up: bytes(appState.dataUsageStore.thisMonth.uploadedBytes))
        }
    }

    private var latencySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Latency (\(appState.settings.latency.resolvedHost))")
            if appState.settings.latency.isEnabled {
                let l = appState.latencyStatistics
                HStack {
                    LabeledValue("Average", "\(Int(l.average)) ms")
                    LabeledValue("Min", "\(Int(l.minimum)) ms")
                    LabeledValue("Max", "\(Int(l.maximum)) ms")
                    LabeledValue("Loss", String(format: "%.1f%%", l.packetLossPercent))
                }
            } else {
                Text("Latency monitoring is disabled in Settings.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader("Connection History")
            let summary = appState.connectionHistoryStore.summary
            if summary == .empty {
                Text("No disconnects recorded yet.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            } else {
                HStack {
                    LabeledValue("Disconnects", "\(summary.disconnectCount)")
                    LabeledValue("Downtime", formattedDuration(summary.totalDowntime))
                }
            }
        }
    }

    private var speedTestSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Speed Test")
            SpeedTestPanel()
        }
    }

    private func rate(_ bps: Double) -> String { ByteFormatter.formatRate(bytesPerSecond: bps, decimalPlaces: 1) }
    private func bytes(_ b: UInt64) -> String { ByteFormatter.formatBytes(Double(b)) }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.netPulseSectionTitle)
            .foregroundStyle(Color.netPulseTextSecondary)
    }
}

private struct StatRow: View {
    let label: String
    let down: String
    let up: String
    init(_ label: String, down: String, up: String) {
        self.label = label; self.down = down; self.up = up
    }
    var body: some View {
        HStack {
            Text(label).font(.netPulseBody).foregroundStyle(Color.netPulseTextSecondary)
            Spacer()
            Text(down).font(.netPulseBody).foregroundStyle(Color.netPulseDownload)
            Text(up).font(.netPulseBody).foregroundStyle(Color.netPulseUpload)
        }
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.netPulseSettingsLabel)
            Text(label).font(.netPulseCaption).foregroundStyle(Color.netPulseTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
