import SwiftUI
import Charts
import NetPulseCore

struct GraphSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Preview") {
                preview
                    .frame(height: 140)
                    .listRowInsets(EdgeInsets())
                    .padding(8)
            }

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

    @ViewBuilder
    private var preview: some View {
        let samples = self.samples
        if samples.isEmpty {
            EmptyStateView(
                icon: "waveform.path.ecg",
                title: "No traffic yet",
                message: "This fills in as NetPulse observes real throughput — the exact same graph shown in the menu bar popup."
            )
        } else {
            Chart {
                if appState.settings.showDownloadInGraph {
                    ForEach(samples) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Download", sample.downloadBytesPerSecond)
                        )
                        .foregroundStyle(Color.netPulseDownload)
                        .interpolationMethod(.monotone)
                    }
                }
                if appState.settings.showUploadInGraph {
                    ForEach(samples) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Upload", sample.uploadBytesPerSecond)
                        )
                        .foregroundStyle(Color.netPulseUpload)
                        .interpolationMethod(.monotone)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let bytes = value.as(Double.self) {
                            Text(ByteFormatter.formatBytes(bytes, decimalPlaces: 0)).font(.netPulseCaption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
        }
    }

    private var samples: [NetworkSample] {
        let raw = appState.trafficSampler.samples(inLast: appState.settings.graphTimeWindow.rawValue)
        return SampleDownsampler.downsample(raw, maxPoints: 90)
    }
}
