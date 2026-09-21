import Foundation
import Combine
import NetPulseCore

/// Owns the persisted day-by-day usage ledger and exposes rolled-up totals
/// for Today / This Week / This Month. Values are derived from observed
/// interface counters, not carrier billing data — the UI must say so.
final class DataUsageStore: ObservableObject {
    @Published private(set) var today = DataUsageTotals(downloadedBytes: 0, uploadedBytes: 0)
    @Published private(set) var thisWeek = DataUsageTotals(downloadedBytes: 0, uploadedBytes: 0)
    @Published private(set) var thisMonth = DataUsageTotals(downloadedBytes: 0, uploadedBytes: 0)

    private var ledger: DataUsageLedger
    private let fileName = "data_usage.json"
    private let persistence: PersistenceController
    private var retentionDays: Int

    init(persistence: PersistenceController = .shared, retentionDays: Int = 90) {
        self.persistence = persistence
        self.retentionDays = retentionDays
        let storedDays = persistence.load([String: DailyUsage].self, fileName: fileName) ?? [:]
        self.ledger = DataUsageLedger(days: storedDays)
        recomputeRollups()
    }

    func recordBytes(downloaded: UInt64, uploaded: UInt64, at date: Date = Date()) {
        guard downloaded > 0 || uploaded > 0 else { return }
        let key = DayKeyFormatter.key(for: date)
        ledger.addBytes(downloaded: downloaded, uploaded: uploaded, toDay: key)
        recomputeRollups()
        persist()
    }

    func updateRetention(days: Int) {
        retentionDays = days
        trimExpired()
    }

    func reset() {
        ledger.reset()
        recomputeRollups()
        persist()
    }

    private func trimExpired() {
        let keep = Set(DayKeyFormatter.recentDayKeys(count: retentionDays))
        ledger.trim(keepingDayKeys: keep)
        recomputeRollups()
        persist()
    }

    private func recomputeRollups() {
        let now = Date()
        today = ledger.totals(forDayKeys: [DayKeyFormatter.key(for: now)])
        thisWeek = ledger.totals(forDayKeys: DayKeyFormatter.recentDayKeys(count: 7, endingAt: now))
        thisMonth = ledger.totals(forDayKeys: DayKeyFormatter.recentDayKeys(count: 30, endingAt: now))
    }

    private func persist() {
        persistence.save(ledger.days, fileName: fileName)
    }
}
