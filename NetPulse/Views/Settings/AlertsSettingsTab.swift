import SwiftUI
import NetPulseCore

struct AlertsSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            if appState.notificationsAuthorized == false {
                Section {
                    Text("macOS hasn't granted NetPulse permission to post notifications, so no alert below can be delivered. Enable it in System Settings → Notifications → NetPulse.")
                        .font(.netPulseCaption)
                        .foregroundStyle(Color.netPulseWarning)
                }
            }

            ForEach($appState.settings.alertRules) { $rule in
                Section(rule.kind.title) {
                    Toggle("Enabled", isOn: $rule.isEnabled)

                    if rule.kind.usesThreshold {
                        HStack {
                            Text("Threshold")
                            Slider(value: $rule.thresholdValue, in: thresholdRange(for: rule.kind))
                            Text(thresholdLabel(for: rule))
                                .font(.netPulseCaption)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }

                    HStack {
                        Text("Cooldown")
                        Slider(value: $rule.cooldownSeconds, in: 10...600)
                        Text("\(Int(rule.cooldownSeconds))s")
                            .font(.netPulseCaption)
                            .frame(width: 50, alignment: .trailing)
                    }

                    Toggle("Play sound", isOn: $rule.playSound)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func thresholdRange(for kind: AlertKind) -> ClosedRange<Double> {
        switch kind {
        case .downloadAbove, .uploadAbove: return (1024 * 1024)...(500 * 1024 * 1024)
        case .latencyAbove: return 10...1000
        case .packetLossAbove: return 1...100
        default: return 0...1
        }
    }

    private func thresholdLabel(for rule: AlertRule) -> String {
        switch rule.kind {
        case .downloadAbove, .uploadAbove:
            return ByteFormatter.formatRate(bytesPerSecond: rule.thresholdValue, decimalPlaces: 0)
        case .latencyAbove:
            return "\(Int(rule.thresholdValue)) ms"
        case .packetLossAbove:
            return "\(Int(rule.thresholdValue))%"
        default:
            return ""
        }
    }
}
