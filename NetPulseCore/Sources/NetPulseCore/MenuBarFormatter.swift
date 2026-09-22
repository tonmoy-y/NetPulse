import Foundation

public enum MenuBarDisplayMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case arrowsInline      // ↓ 2.4 MB/s  ↑ 384 KB/s
    case arrowsStacked     // two lines
    case lettered          // D 2.4 MB/s U 384 KB/s
    case valueFirst        // 2.4 MB/s ↓  |  384 KB/s ↑
    case downloadOnly
    case uploadOnly

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .arrowsInline: return "Arrows (inline)"
        case .arrowsStacked: return "Arrows (stacked)"
        case .lettered: return "Lettered (D / U)"
        case .valueFirst: return "Value first"
        case .downloadOnly: return "Download only"
        case .uploadOnly: return "Upload only"
        }
    }
}

public struct MenuBarDisplayOptions: Codable, Equatable {
    public var mode: MenuBarDisplayMode = .arrowsInline
    public var showUnits: Bool = true
    public var decimalPlaces: Int = 1
    public var separator: String = "  "
    public var compact: Bool = false

    public init() {}
}

/// Pure formatter that turns a throughput reading into the exact string shown
/// in the status bar, independent of AppKit so it's fully unit-testable.
public enum MenuBarFormatter {
    public static func format(downloadBps: Double, uploadBps: Double, options: MenuBarDisplayOptions) -> String {
        let down = rate(downloadBps, options: options)
        let up = rate(uploadBps, options: options)

        switch options.mode {
        case .arrowsInline:
            return "↓ \(down)\(options.separator)↑ \(up)"
        case .arrowsStacked:
            return "↓ \(down)\n↑ \(up)"
        case .lettered:
            return "D \(down)\(options.separator)U \(up)"
        case .valueFirst:
            return "\(down) ↓\(options.separator)|\(options.separator)\(up) ↑"
        case .downloadOnly:
            return "↓ \(down)"
        case .uploadOnly:
            return "↑ \(up)"
        }
    }

    private static func rate(_ bytesPerSecond: Double, options: MenuBarDisplayOptions) -> String {
        let (value, unit) = ByteFormatter.components(bytes: bytesPerSecond, decimalPlaces: options.decimalPlaces)
        guard options.showUnits else { return value }
        // Compact mode exists to save menu bar width: drop the space before
        // the unit and the "/s" suffix ("2.4MB" instead of "2.4 MB/s").
        return options.compact ? "\(value)\(unit)" : "\(value) \(unit)/s"
    }
}
