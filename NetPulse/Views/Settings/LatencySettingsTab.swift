import SwiftUI
import NetPulseCore

struct LatencySettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section {
                Toggle("Enable latency monitoring", isOn: $appState.settings.latency.isEnabled)

                Picker("Target host", selection: $appState.settings.latency.target) {
                    Text("1.1.1.1 (Cloudflare)").tag(PingTarget.cloudflare)
                    Text("8.8.8.8 (Google)").tag(PingTarget.google)
                    Text("9.9.9.9 (Quad9)").tag(PingTarget.quad9)
                    Text("Custom").tag(PingTarget.custom)
                }
                .disabled(!appState.settings.latency.isEnabled)

                if appState.settings.latency.target == .custom {
                    TextField("Hostname or IP", text: $appState.settings.latency.customHost)
                        .disabled(!appState.settings.latency.isEnabled)
                }

                Picker("Ping interval", selection: pingIntervalBinding) {
                    Text("Off").tag(0.0)
                    Text("Every 2 seconds").tag(2.0)
                    Text("Every 5 seconds").tag(5.0)
                    Text("Every 10 seconds").tag(10.0)
                    Text("Every 30 seconds").tag(30.0)
                }
            }

            Section {
                Text("NetPulse sends a single ICMP echo per interval — never a flood — using the system ping utility.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section("Network Quality Thresholds") {
                Stepper(value: $appState.settings.qualityThresholds.excellentLatencyMs, in: 5...200, step: 5) {
                    Text("Excellent under \(Int(appState.settings.qualityThresholds.excellentLatencyMs)) ms")
                }
                Stepper(value: $appState.settings.qualityThresholds.goodLatencyMs, in: 20...300, step: 5) {
                    Text("Good under \(Int(appState.settings.qualityThresholds.goodLatencyMs)) ms")
                }
                Stepper(value: $appState.settings.qualityThresholds.fairLatencyMs, in: 50...500, step: 10) {
                    Text("Fair under \(Int(appState.settings.qualityThresholds.fairLatencyMs)) ms")
                }
            }
        }
        .formStyle(.grouped)
    }

    // Lets "Ping interval" itself carry an explicit Off value, in addition to
    // the "Enable latency monitoring" toggle above — both control the same
    // underlying isEnabled flag, so either one turns pinging fully off.
    private var pingIntervalBinding: Binding<Double> {
        Binding(
            get: { appState.settings.latency.isEnabled ? appState.settings.latency.intervalSeconds : 0 },
            set: { newValue in
                if newValue == 0 {
                    appState.settings.latency.isEnabled = false
                } else {
                    appState.settings.latency.intervalSeconds = newValue
                    appState.settings.latency.isEnabled = true
                }
            }
        )
    }
}
