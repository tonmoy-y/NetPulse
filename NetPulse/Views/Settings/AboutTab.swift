import SwiftUI

struct AboutTab: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 14) {
            NetPulseMark(size: 48)
                .padding(.top, 20)

            Text("NetPulse")
                .font(.system(size: 20, weight: .semibold, design: .rounded))

            Text("Lightweight network monitoring for macOS.")
                .font(.netPulseBody)
                .foregroundStyle(Color.netPulseTextSecondary)

            Text("Version \(version) (\(build))")
                .font(.netPulseCaption)
                .foregroundStyle(Color.netPulseTextMuted)

            VStack(spacing: 6) {
                Link("Source on GitHub", destination: URL(string: "https://github.com/tonmoy-y/NetPulse")!)
                Text("MIT License")
                Text("© 2026 Tonmoy Sarker Sourav")
            }
            .font(.netPulseCaption)
            .foregroundStyle(Color.netPulseTextSecondary)

            Text("NetPulse runs entirely on-device. No accounts, no telemetry, no cloud backend.")
                .font(.netPulseCaption)
                .foregroundStyle(Color.netPulseTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
