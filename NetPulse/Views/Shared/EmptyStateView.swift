import SwiftUI

/// Original, contextual empty-state messaging — never a bare "No data available."
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(Color.netPulseTextMuted)
            Text(title)
                .font(.netPulseSettingsLabel)
            Text(message)
                .font(.netPulseCaption)
                .foregroundStyle(Color.netPulseTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
}
