import SwiftUI

/// The NetPulse brand mark: an original geometric "signal pulse" — a
/// waveform that steps up and down like a heartbeat trace, read either as
/// data flowing through a connection or as two arrows (down/up) merged into
/// one continuous line. Deliberately not a Wi-Fi glyph, not Apple's
/// networking symbols, and not another monitoring app's icon.
struct NetPulseMark: View {
    var size: CGFloat = 24
    var color: Color = .netPulsePrimary

    var body: some View {
        Canvas { context, canvasSize in
            var path = Path()
            let w = canvasSize.width
            let h = canvasSize.height
            let midY = h * 0.55

            path.move(to: CGPoint(x: 0, y: midY))
            path.addLine(to: CGPoint(x: w * 0.22, y: midY))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.18))
            path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.82))
            path.addLine(to: CGPoint(x: w * 0.70, y: midY))
            path.addLine(to: CGPoint(x: w, y: midY))

            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: max(1.5, w * 0.09), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct NetPulseAppIconPreview: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 42, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.netPulsePrimary, Color.netPulseSecondary],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(NetPulseMark(size: 120, color: .white))
            .frame(width: 200, height: 200)
    }
}

#Preview {
    NetPulseAppIconPreview()
}
