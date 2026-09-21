import SwiftUI
import NetPulseCore

struct QualityBadge: View {
    let quality: NetworkQuality

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(quality.rawValue)
                .font(.netPulseCaption)
                .foregroundStyle(Color.netPulseTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.netPulseBorder.opacity(0.5)))
    }

    private var color: Color {
        switch quality {
        case .excellent: return .netPulseSuccess
        case .good: return .netPulseSuccess
        case .fair: return .netPulseWarning
        case .poor: return .netPulseError
        case .offline: return .netPulseTextMuted
        }
    }
}
