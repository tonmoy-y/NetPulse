import Foundation

/// Converts raw byte counts and throughput into compact, human-readable strings.
public enum ByteFormatter {

    public enum Unit: String, CaseIterable {
        case bytes = "B"
        case kilobytes = "KB"
        case megabytes = "MB"
        case gigabytes = "TB" // placeholder, unused directly
    }

    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    /// Formats a throughput value (bytes per second) as e.g. "2.42 MB/s".
    public static func formatRate(bytesPerSecond: Double, decimalPlaces: Int = 2) -> String {
        "\(formatBytes(bytesPerSecond, decimalPlaces: decimalPlaces))/s"
    }

    /// Formats a raw byte count as e.g. "842 MB", "7.4 GB".
    public static func formatBytes(_ bytes: Double, decimalPlaces: Int = 2) -> String {
        guard bytes.isFinite, bytes >= 0 else { return "0 B" }
        if bytes < 1 {
            return "0 B"
        }

        var value = bytes
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        let places = unitIndex == 0 ? 0 : decimalPlaces
        return String(format: "%.\(places)f %@", value, units[unitIndex])
    }

    /// Returns (value, unit) split for callers that want to style them independently.
    public static func components(bytes: Double, decimalPlaces: Int = 2) -> (value: String, unit: String) {
        guard bytes.isFinite, bytes >= 0, bytes >= 1 else { return ("0", "B") }
        var value = bytes
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        let places = unitIndex == 0 ? 0 : decimalPlaces
        return (String(format: "%.\(places)f", value), units[unitIndex])
    }
}
