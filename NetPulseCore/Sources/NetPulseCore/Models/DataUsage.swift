import Foundation

/// A single day's accumulated traffic, keyed by calendar day (local time).
public struct DailyUsage: Codable, Equatable, Identifiable {
    public var id: String { dayKey }
    public let dayKey: String   // "yyyy-MM-dd"
    public var downloadedBytes: UInt64
    public var uploadedBytes: UInt64

    public init(dayKey: String, downloadedBytes: UInt64 = 0, uploadedBytes: UInt64 = 0) {
        self.dayKey = dayKey
        self.downloadedBytes = downloadedBytes
        self.uploadedBytes = uploadedBytes
    }
}

public struct DataUsageTotals: Equatable {
    public let downloadedBytes: UInt64
    public let uploadedBytes: UInt64
}

/// Pure aggregation logic over a day-keyed ledger. Persistence and calendar
/// wall-clock reads live outside this type so it stays deterministic and testable.
public struct DataUsageLedger {
    public private(set) var days: [String: DailyUsage]

    public init(days: [String: DailyUsage] = [:]) {
        self.days = days
    }

    public mutating func addBytes(downloaded: UInt64, uploaded: UInt64, toDay dayKey: String) {
        var entry = days[dayKey] ?? DailyUsage(dayKey: dayKey)
        entry.downloadedBytes += downloaded
        entry.uploadedBytes += uploaded
        days[dayKey] = entry
    }

    public func totals(forDayKeys keys: [String]) -> DataUsageTotals {
        var down: UInt64 = 0
        var up: UInt64 = 0
        for key in keys {
            if let entry = days[key] {
                down += entry.downloadedBytes
                up += entry.uploadedBytes
            }
        }
        return DataUsageTotals(downloadedBytes: down, uploadedBytes: up)
    }

    public mutating func reset() {
        days.removeAll()
    }

    /// Removes entries older than `retentionDays` relative to `referenceKeys` (the
    /// most recent N day keys that should always be kept, oldest excluded).
    public mutating func trim(keepingDayKeys keysToKeep: Set<String>) {
        days = days.filter { keysToKeep.contains($0.key) }
    }
}

public enum DayKeyFormatter {
    private static func formatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f
    }

    public static func key(for date: Date) -> String {
        formatter().string(from: date)
    }

    /// Returns day keys for the last `count` days including today, oldest first.
    public static func recentDayKeys(count: Int, endingAt referenceDate: Date = Date(), calendar: Calendar = .current) -> [String] {
        (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: referenceDate).map(key(for:))
        }
    }
}
