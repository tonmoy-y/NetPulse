import Foundation
import Combine
import ServiceManagement
import NetPulseCore

/// Central coordinator that owns every monitor/store and wires them
/// together. Views read from here; nothing talks to the low-level monitors
/// directly.
@MainActor
final class AppState: ObservableObject {
    /// Single shared instance. AppDelegate starts it at launch (independent of
    /// whether the popover has ever been opened); SwiftUI views bind to the
    /// same instance so menu bar updates never depend on UI being visible.
    static let shared = AppState()

    @Published var settings: AppSettings {
        didSet { persistence.saveSettings(settings); applySettingsSideEffects(previous: oldValue) }
    }

    @Published private(set) var trafficStatistics = TrafficStatistics()
    @Published private(set) var latencyStatistics = LatencyStatistics()
    @Published private(set) var networkQuality: NetworkQuality = .offline
    @Published private(set) var publicIP: String?

    /// nil until macOS answers the authorization request. False means
    /// notifications were denied or errored, so no alert can ever be
    /// delivered — the Alerts settings tab says so rather than letting the
    /// feature look functional while silently dropping everything.
    @Published private(set) var notificationsAuthorized: Bool?

    let trafficSampler = TrafficSampler()
    let interfaceMonitor = InterfaceMonitor()
    let latencyMonitor = LatencyMonitor()
    let dataUsageStore: DataUsageStore
    let connectionHistoryStore = ConnectionHistoryStore()
    let speedTestService = SpeedTestService()
    let updateChecker = UpdateChecker()
    let selfUpdateInstaller = SelfUpdateInstaller()

    private var alertEngine: AlertEngine!
    private let persistence: PersistenceController
    private let statisticsAccumulator: TrafficStatisticsAccumulator
    private var cancellables = Set<AnyCancellable>()
    private var lastThroughputSampleTime: Date?

    /// `@Published` replays its current value to new subscribers, so the
    /// initial `isConnected == false` would fire a "connection lost" alert
    /// the instant the app launched, immediately followed by "connection
    /// restored" once NWPathMonitor reported the real state — a spurious
    /// pair of notifications on every single launch. The first observed
    /// state establishes a baseline instead of counting as a transition.
    private var hasObservedInitialConnectionState = false

    /// Lifetime totals are written to disk on a timer rather than on every
    /// sample — at a 1-second sampling cadence that was a disk write every
    /// second, forever, for a value that only needs to survive a quit.
    private var lastTotalsPersist = Date.distantPast
    private let totalsPersistInterval: TimeInterval = 30

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let loadedSettings = persistence.loadSettings()
        self.settings = loadedSettings
        self.dataUsageStore = DataUsageStore(persistence: persistence, retentionDays: loadedSettings.dataUsage.retentionDays)

        let startingTotals = persistence.load(TrafficStatistics.self, fileName: "lifetime_totals.json")
        self.statisticsAccumulator = TrafficStatisticsAccumulator(
            startingTotals: (
                downloaded: startingTotals?.totalDownloadedBytes ?? 0,
                uploaded: startingTotals?.totalUploadedBytes ?? 0
            )
        )

        self.alertEngine = AlertEngine(rules: loadedSettings.alertRules) { [weak self] updated in
            self?.settings.alertRules = updated
        }
        self.alertEngine.onAuthorizationResolved = { [weak self] granted in
            self?.notificationsAuthorized = granted
        }

        self.dataUsageStore.persistAcrossLaunches = loadedSettings.dataUsage.persistAcrossLaunches

        trafficSampler.primaryInterfaceProvider = { [weak self] in
            self?.interfaceMonitor.primaryInterface?.bsdName
        }

        wireUpMonitors()
    }

    func start() {
        // Start interface discovery first so Auto mode's primaryInterfaceProvider
        // has a real answer by the time the first throughput tick fires.
        interfaceMonitor.start()

        trafficSampler.interfaceSelection = settings.interfaceSelection
        trafficSampler.isPaused = settings.isMonitoringPaused
        trafficSampler.start(interval: settings.refreshInterval.rawValue)

        restartLatencyMonitor()

        if settings.checkForUpdatesAutomatically {
            updateChecker.checkForUpdates()
        }
        // Previously only fetched when the toggle was flipped, so a user who
        // enabled it once saw nothing on every later launch.
        refreshPublicIP()
    }

    func stop() {
        trafficSampler.stop()
        interfaceMonitor.stop()
        latencyMonitor.stop()
        flushPendingWrites()
    }

    /// Writes anything held back by write-throttling straight away. Called
    /// on quit and before sleep so throttling never costs recorded data.
    func flushPendingWrites() {
        persistTotals()
        dataUsageStore.flush()
    }

    private func persistTotals() {
        persistence.save(trafficStatistics, fileName: "lifetime_totals.json")
        lastTotalsPersist = Date()
    }

    // MARK: - Wiring

    private func wireUpMonitors() {
        trafficSampler.onSample = { [weak self] sample in
            self?.handle(sample: sample)
        }

        interfaceMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] connected in
                guard let self else { return }
                self.connectionHistoryStore.record(isConnected: connected, interfaceName: self.interfaceMonitor.primaryInterface?.displayName)
                if self.hasObservedInitialConnectionState {
                    self.alertEngine.evaluateConnection(isConnected: connected)
                } else {
                    self.hasObservedInitialConnectionState = true
                }
                self.recomputeQuality()
            }
            .store(in: &cancellables)

        latencyMonitor.$statistics
            .sink { [weak self] stats in
                guard let self else { return }
                self.latencyStatistics = stats
                if let current = stats.current {
                    self.alertEngine.evaluateLatency(ms: current)
                }
                self.alertEngine.evaluatePacketLoss(percent: stats.packetLossPercent)
                self.recomputeQuality()
            }
            .store(in: &cancellables)
    }

    private func handle(sample: NetworkSample) {
        let now = sample.timestamp
        let elapsed = lastThroughputSampleTime.map { now.timeIntervalSince($0) } ?? settings.refreshInterval.rawValue
        lastThroughputSampleTime = now

        statisticsAccumulator.record(sample, elapsedSeconds: elapsed)
        trafficStatistics = statisticsAccumulator.statistics

        let downloadedDelta = UInt64(max(0, sample.downloadBytesPerSecond * elapsed))
        let uploadedDelta = UInt64(max(0, sample.uploadBytesPerSecond * elapsed))
        dataUsageStore.recordBytes(downloaded: downloadedDelta, uploaded: uploadedDelta, at: now)

        if now.timeIntervalSince(lastTotalsPersist) >= totalsPersistInterval {
            persistTotals()
        }
        alertEngine.evaluateThroughput(downloadBps: sample.downloadBytesPerSecond, uploadBps: sample.uploadBytesPerSecond)
    }

    private func recomputeQuality() {
        // "Stable" throughput heuristic: don't reward a single fast sample —
        // require at least a few real measurements before calling it excellent.
        let stable = trafficSampler.recentSamples.count >= 3
        networkQuality = NetworkQualityEvaluator.evaluate(
            isConnected: interfaceMonitor.isConnected,
            averageLatencyMs: latencyStatistics.average,
            packetLossPercent: latencyStatistics.packetLossPercent,
            recentThroughputStable: stable,
            thresholds: settings.qualityThresholds
        )
    }

    // MARK: - Settings side effects

    private func applySettingsSideEffects(previous: AppSettings) {
        if previous.refreshInterval != settings.refreshInterval {
            trafficSampler.reschedule(interval: settings.refreshInterval.rawValue)
        }
        if previous.interfaceSelection != settings.interfaceSelection {
            trafficSampler.interfaceSelection = settings.interfaceSelection
        }
        if previous.isMonitoringPaused != settings.isMonitoringPaused {
            trafficSampler.isPaused = settings.isMonitoringPaused
        }
        if previous.latency != settings.latency {
            restartLatencyMonitor()
        }
        if previous.dataUsage.retentionDays != settings.dataUsage.retentionDays {
            dataUsageStore.updateRetention(days: settings.dataUsage.retentionDays)
        }
        if previous.dataUsage.persistAcrossLaunches != settings.dataUsage.persistAcrossLaunches {
            dataUsageStore.persistAcrossLaunches = settings.dataUsage.persistAcrossLaunches
        }
        if previous.launchAtLogin != settings.launchAtLogin {
            LoginItemManager.setEnabled(settings.launchAtLogin)
        }
        if previous.alertRules != settings.alertRules {
            alertEngine.updateRules(settings.alertRules)
        }
        if previous.privacy.publicIPLookupEnabled != settings.privacy.publicIPLookupEnabled {
            if settings.privacy.publicIPLookupEnabled {
                refreshPublicIP()
            } else {
                publicIP = nil
            }
        }
    }

    private func restartLatencyMonitor() {
        guard settings.latency.isEnabled, !settings.latency.resolvedHost.isEmpty else {
            latencyMonitor.stop()
            return
        }
        latencyMonitor.start(host: settings.latency.resolvedHost, interval: settings.latency.intervalSeconds)
    }

    func refreshPublicIP() {
        guard settings.privacy.publicIPLookupEnabled else { return }
        Task { [weak self] in
            let ip = await PublicIPService.fetchPublicIP()
            await MainActor.run { self?.publicIP = ip }
        }
    }

    func resetAllSettings() {
        persistence.resetSettings()
        settings = AppSettings()
    }
}
