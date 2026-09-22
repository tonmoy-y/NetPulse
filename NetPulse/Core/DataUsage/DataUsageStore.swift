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

    /// Honors Settings → Data Usage → "Persist usage across launches". When
    /// off, usage is still tracked for the current session but never
    /// written to disk, and anything previously written is removed.
    var persistAcrossLaunches: Bool = true {
        didSet {
            guard persistAcrossLaunches != oldValue else { return }
            if persistAcrossLaunches {
                persist(force: true)
            } else {
                persistence.delete(fileName: fileName)
            }
        }
    }

    // Written on a timer rather than on every sample: at a 1-second
    // sampling cadence, persisting per sample meant a disk write every
    // second for the entire time the app was running.
    private var lastPersist = Date.distantPast
    private let persistInterval: TimeInterval = 30

    /// Tracked so retention trimming runs when the day rolls over, not just
    /// at launch.
    private var currentDayKey: String

    init(persistence: PersistenceController = .shared, retentionDays: Int = 90) {
        self.persistence = persistence
        self.retentionDays = retentionDays
        let storedDays = persistence.load([String: DailyUsage].self, fileName: fileName) ?? [:]
        self.ledger = DataUsageLedger(days: storedDays)
        self.currentDayKey = DayKeyFormatter.key(for: Date())
        recomputeRollups()
        // Retention used to be applied only when the user changed the
        // retention setting, so on a normal install the ledger grew
        // forever and "Retention: 90 days" was never actually enforced.
        trimExpired()
    }

    func recordBytes(downloaded: UInt64, uploaded: UInt64, at date: Date = Date()) {
        guard downloaded > 0 || uploaded > 0 else { return }
        let key = DayKeyFormatter.key(for: date)
        ledger.addBytes(downloaded: downloaded, uploaded: uploaded, toDay: key)

        if key != currentDayKey {
            currentDayKey = key
            trimExpired() // also persists
            return
        }

        recomputeRollups()
        persist()
    }

    /// Writes immediately regardless of the throttle — used on quit/sleep.
    func flush() {
        persist(force: true)
    }

    func updateRetention(days: Int) {
        retentionDays = days
        trimExpired()
    }

    func reset() {
        ledger.reset()
        recomputeRollups()
        persist(force: true)
    }

    private func trimExpired() {
        let keep = Set(DayKeyFormatter.recentDayKeys(count: retentionDays))
        ledger.trim(keepingDayKeys: keep)
        recomputeRollups()
        persist(force: true)
    }

    private func recomputeRollups() {
        let now = Date()
        today = ledger.totals(forDayKeys: [DayKeyFormatter.key(for: now)])
        thisWeek = ledger.totals(forDayKeys: DayKeyFormatter.recentDayKeys(count: 7, endingAt: now))
        thisMonth = ledger.totals(forDayKeys: DayKeyFormatter.recentDayKeys(count: 30, endingAt: now))
    }

    private func persist(force: Bool = false) {
        guard persistAcrossLaunches else { return }
        guard force || Date().timeIntervalSince(lastPersist) >= persistInterval else { return }
        persistence.save(ledger.days, fileName: fileName)
        lastPersist = Date()
    }
}
