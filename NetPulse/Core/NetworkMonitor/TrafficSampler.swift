import Foundation
import Combine
import NetPulseCore

/// Polls interface byte counters on a timer and publishes real throughput
/// samples. This is the only source of speed data in the app — there is no
/// synthetic/demo mode.
final class TrafficSampler: ObservableObject {
    @Published private(set) var latestSample: NetworkSample = NetworkSample(timestamp: Date(), downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
    @Published private(set) var recentSamples: [NetworkSample] = []

    private var timer: DispatchSourceTimer?
    private var previousReading: InterfaceCounterReading?
    private var previousBsdName: String?
    private let maxRetainedSamples = 3600 // enough for the 1-hour graph window at 1s resolution

    var interfaceSelection: InterfaceSelectionMode = .auto
    var isPaused: Bool = false

    /// Supplies the BSD name of the currently-primary interface (the same
    /// one InterfaceMonitor shows as "Interface" in the popup) for Auto
    /// mode. Set by AppState. If nil (e.g. briefly at launch before the
    /// first interface scan completes), Auto mode falls back to summing all
    /// non-virtual interfaces rather than reporting nothing.
    var primaryInterfaceProvider: (() -> String?)?

    func start(interval: TimeInterval) {
        stop()
        previousReading = nil

        let queue = DispatchQueue(label: "com.netpulse.trafficsampler", qos: .utility)
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(20))
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        timer = source
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func reschedule(interval: TimeInterval) {
        guard timer != nil else { return }
        start(interval: interval)
    }

    private func tick() {
        guard !isPaused else { return }

        let allCounters = InterfaceCounterReader.readAll()
        let selectedName: String
        let raw: InterfaceCounterReader.RawCounters

        switch interfaceSelection {
        case .auto:
            // Track ONE real interface's counters, not a sum across every
            // interface getifaddrs reports. macOS surfaces a churn of
            // ephemeral pseudo-interfaces (awdl0, llw0, bridge100, utun*,
            // ap1, ...) that flap up/down independently of real traffic;
            // summing them made the aggregate occasionally dip below its
            // previous value between ticks, which ThroughputCalculator
            // clamps to a false 0 B/s. Following the same single interface
            // InterfaceMonitor already identified as primary avoids that
            // entirely and keeps the menu bar in sync with the interface
            // name shown in the popup.
            if let primaryName = primaryInterfaceProvider?(),
               let match = allCounters.first(where: { $0.bsdName == primaryName }) {
                raw = match
                selectedName = primaryName
            } else {
                raw = InterfaceCounterReader.aggregate(allCounters)
                selectedName = "auto"
            }
        case .specific(let bsdName):
            if let match = allCounters.first(where: { $0.bsdName == bsdName }) {
                raw = match
                selectedName = bsdName
            } else {
                raw = InterfaceCounterReader.aggregate(allCounters)
                selectedName = "auto"
            }
        }

        let now = Date()
        let currentReading = InterfaceCounterReading(timestamp: now, bytesReceived: raw.bytesReceived, bytesSent: raw.bytesSent)

        defer {
            previousReading = currentReading
            previousBsdName = selectedName
        }

        // If the underlying interface changed (e.g. Wi-Fi -> Ethernet switch),
        // discard the stale baseline rather than reporting a bogus spike.
        guard let previous = previousReading, previousBsdName == selectedName,
              let sample = ThroughputCalculator.sample(previous: previous, current: currentReading) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.latestSample = sample
            self.recentSamples.append(sample)
            if self.recentSamples.count > self.maxRetainedSamples {
                self.recentSamples.removeFirst(self.recentSamples.count - self.maxRetainedSamples)
            }
            self.onSample?(sample)
        }
    }

    var onSample: ((NetworkSample) -> Void)?

    func samples(inLast window: TimeInterval) -> [NetworkSample] {
        let cutoff = Date().addingTimeInterval(-window)
        return recentSamples.filter { $0.timestamp >= cutoff }
    }
}
