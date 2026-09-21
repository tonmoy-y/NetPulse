import SwiftUI
import NetPulseCore

struct SpeedTestPanel: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var service: SpeedTestService

    init() {
        _service = ObservedObject(wrappedValue: AppState.shared.speedTestService)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch service.phase {
            case .idle:
                Button("Start Speed Test") { service.start() }
                    .disabled(!appState.settings.privacy.speedTestEnabled)
                Text("Manual only — uses real bandwidth and never runs automatically.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)

            case .measuringLatency:
                ProgressView("Measuring latency…").font(.netPulseCaption)

            case .measuringDownload:
                ProgressView("Measuring download…").font(.netPulseCaption)

            case .measuringUpload:
                ProgressView("Measuring upload…").font(.netPulseCaption)

            case .finished(let result):
                HStack {
                    LabeledValue("Download", ByteFormatter.formatRate(bytesPerSecond: result.downloadBps, decimalPlaces: 1))
                    LabeledValue("Upload", ByteFormatter.formatRate(bytesPerSecond: result.uploadBps, decimalPlaces: 1))
                    LabeledValue("Latency", "\(Int(result.latencyMs)) ms")
                    LabeledValue("Jitter", "\(Int(result.jitterMs)) ms")
                }
                Button("Run Again") { service.start() }
                    .font(.netPulseCaption)

            case .failed(let message):
                Text("Speed test failed: \(message)")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseError)
                Button("Try Again") { service.start() }
                    .font(.netPulseCaption)
            }
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
