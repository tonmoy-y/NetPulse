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
    private let maxRetainedSamples = 3600 // enough for the 1-hour graph window at 1s resolution

    // The counter reading a sample is measured FROM, and the interface it
    // was taken on. We deliberately do NOT diff every tick against the
    // immediately-previous tick: macOS updates an interface's if_data byte
    // counters in batches rather than continuously, so at fast refresh
    // intervals (100-500ms) a large fraction of ticks would see literally
    // no change since the last poll and report a spurious 0 B/s even while
    // real traffic is flowing — the counter just hadn't been updated yet.
    // Instead we keep a baseline and only compute+publish a new sample once
    // at least `minimumSampleWindow` has elapsed since it, so every
    // published sample spans enough wall-clock time to reliably observe a
    // real counter update.
    private var windowStart: InterfaceCounterReading?
    private var windowStartName: String?
    private let minimumSampleWindow: TimeInterval = 1.0

    // Once Auto mode has locked onto a real primary interface, keep using
    // it even if InterfaceMonitor's primary-interface detection transiently
    // reports nil (e.g. a momentary isRunning flicker) — otherwise the
    // sampler would keep bouncing onto the full-interface aggregate, whose
    // very different baseline causes exactly the false-zero clamp this
    // whole windowing scheme exists to avoid. A genuine interface switch
    // (Wi-Fi -> Ethernet) still updates this immediately, since
    // primaryInterfaceProvider only returns nil, never a stale name.
    private var lastKnownPrimaryName: String?

    var interfaceSelection: InterfaceSelectionMode = .auto
    var isPaused: Bool = false

    /// Supplies the BSD name of the currently-primary interface (the same
    /// one InterfaceMonitor shows as "Interface" in the popup) for Auto
    /// mode. Set by AppState.
    var primaryInterfaceProvider: (() -> String?)?

    func start(interval: TimeInterval) {
        stop()
        windowStart = nil
        windowStartName = nil

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
            if let primaryName = primaryInterfaceProvider?() {
                lastKnownPrimaryName = primaryName
            }
            if let name = lastKnownPrimaryName, let match = allCounters.first(where: { $0.bsdName == name }) {
                raw = match
                selectedName = name
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

        // The interface we're tracking changed (real switch, or the
        // aggregate<->single-interface fallback kicked in) — reset the
        // baseline rather than diffing across two different counter spaces.
        guard windowStartName == selectedName, let start = windowStart else {
            windowStart = currentReading
            windowStartName = selectedName
            return
        }

        let elapsed = now.timeIntervalSince(start.timestamp)
        guard elapsed >= minimumSampleWindow,
              let sample = ThroughputCalculator.sample(previous: start, current: currentReading) else {
            return
        }

        // Slide the window forward: this sample's end becomes the next one's start.
        windowStart = currentReading

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
