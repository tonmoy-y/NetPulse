import Foundation
import NetPulseCore

/// The only state the menu bar item renders. The status item is visible
/// for the app's whole lifetime, so it's kept deliberately narrow: it
/// publishes only when the displayed text or status dot actually changes,
/// instead of redrawing on every AppState change (latency ticks, settings
/// edits, public IP, etc.) or when an idle link keeps reporting "0 B/s".
@MainActor
final class MenuBarModel: ObservableObject {
    enum StatusDot: Equatable {
        case none, warning, error
    }

    @Published private(set) var text: String = ""
    @Published private(set) var dot: StatusDot = .none

    func update(text newText: String, dot newDot: StatusDot) {
        if newText != text { text = newText }
        if newDot != dot { dot = newDot }
    }
}
