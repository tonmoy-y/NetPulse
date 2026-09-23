import SwiftUI

/// The content rendered in the macOS menu bar. Observes only MenuBarModel,
/// not AppState, so it redraws only when what's shown actually changes.
struct MenuBarLabelView: View {
    @EnvironmentObject private var model: MenuBarModel

    var body: some View {
        HStack(spacing: 4) {
            switch model.dot {
            case .none:
                EmptyView()
            case .warning:
                Circle().fill(Color.netPulseWarning).frame(width: 6, height: 6)
            case .error:
                Circle().fill(Color.netPulseError).frame(width: 6, height: 6)
            }
            Text(model.text)
                .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
        }
    }
}
