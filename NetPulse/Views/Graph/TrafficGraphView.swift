import SwiftUI
import Charts
import NetPulseCore

struct TrafficGraphView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Window", selection: windowBinding) {
                    ForEach(GraphTimeWindow.allCases) { window in
                        Text(window.label).tag(window)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 140)

                Spacer()

                // Bound to the persisted settings, not local view state —
                // otherwise Settings → Graph → "Show download/upload line"
                // had no effect on this graph, and these checkboxes reset
                // every time the popover was reopened.
                Toggle("Download", isOn: $appState.settings.showDownloadInGraph)
                    .toggleStyle(.checkbox)
                    .font(.netPulseCaption)
                Toggle("Upload", isOn: $appState.settings.showUploadInGraph)
                    .toggleStyle(.checkbox)
                    .font(.netPulseCaption)
            }

            if samples.isEmpty {
                EmptyStateView(
                    icon: "waveform.path.ecg",
                    title: "No traffic yet",
                    message: "The graph fills in as NetPulse observes real throughput on this interface."
                )
                .frame(height: 200)
            } else {
                Chart {
                    if appState.settings.showDownloadInGraph {
                        ForEach(samples) { sample in
                            AreaMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("Download", sample.downloadBytesPerSecond)
                            )
                            .foregroundStyle(Color.netPulseDownload.opacity(0.18))
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
                                Text(ByteFormatter.formatBytes(bytes, decimalPlaces: 0))
                                    .font(.netPulseCaption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(14)
    }

    private var samples: [NetworkSample] {
        appState.trafficSampler.samples(inLast: appState.settings.graphTimeWindow.rawValue)
    }

    private var windowBinding: Binding<GraphTimeWindow> {
        Binding(
            get: { appState.settings.graphTimeWindow },
            set: { appState.settings.graphTimeWindow = $0 }
        )
    }
}
