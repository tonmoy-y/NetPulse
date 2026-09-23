import SwiftUI
import Charts
import NetPulseCore

struct TrafficGraphView: View {
    @EnvironmentObject private var appState: AppState

    /// Enough resolution for a ~330pt-wide plot; anything beyond this is
    /// invisible detail that still costs layout and rendering every second.
    private let maxPlottedPoints = 120

    var body: some View {
        let points = chartPoints

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Window", selection: $appState.settings.graphTimeWindow) {
                    ForEach(GraphTimeWindow.allCases) { window in
                        Text(window.label).tag(window)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 140)

                Spacer()

                // Bound to persisted settings so Settings → Graph and these
                // checkboxes stay in sync and survive reopening the popover.
                Toggle("Download", isOn: $appState.settings.showDownloadInGraph)
                    .toggleStyle(.checkbox)
                    .font(.netPulseCaption)
                Toggle("Upload", isOn: $appState.settings.showUploadInGraph)
                    .toggleStyle(.checkbox)
                    .font(.netPulseCaption)
            }

            if points.isEmpty {
                EmptyStateView(
                    icon: "waveform.path.ecg",
                    title: "No traffic yet",
                    message: "The graph fills in as NetPulse observes real throughput on this interface."
                )
                .frame(height: 200)
            } else {
                Chart {
                    if appState.settings.showDownloadInGraph {
                        ForEach(points) { sample in
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
                        ForEach(points) { sample in
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

    private var chartPoints: [NetworkSample] {
        let raw = appState.trafficSampler.samples(inLast: appState.settings.graphTimeWindow.rawValue)
        return SampleDownsampler.downsample(raw, maxPoints: maxPlottedPoints)
    }
}
