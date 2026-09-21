import SwiftUI

struct PrivacySettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section {
                Text("By default NetPulse collects no analytics, no telemetry, and sends nothing anywhere. Throughput, interfaces, graphs, and data usage are all computed entirely on this Mac.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextSecondary)
            }

            Section("Public IP Lookup") {
                Toggle("Look up public IP address", isOn: $appState.settings.privacy.publicIPLookupEnabled)
                Text("Off by default. When enabled, NetPulse makes an external request to a public IP-lookup service each time you open the popup. No other data is sent.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section("Speed Test") {
                Toggle("Allow manual speed test", isOn: $appState.settings.privacy.speedTestEnabled)
                Text("Speed tests only run when you tap Start, never automatically, and consume real bandwidth against a public test endpoint.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }
        }
        .formStyle(.grouped)
    }
}
