import Foundation
import NetPulseCore

/// Polls interface byte counters on a timer and publishes real throughput
/// samples. This is the only source of speed data in the app — there is no
/// synthetic/demo mode.
final class TrafficSampler {
    /// Readings slower than this can't be made reliable (see the windowing
    /// note below), so the timer never ticks faster than this. Previously the
    /// timer ran at the user's 100–500 ms setting and discarded most ticks
    /// after doing a full getifaddrs() walk — wasted wakeups and syscalls.
    static let minimumTickInterval: TimeInterval = 1.0

    private(set) var recentSamples: [NetworkSample] = []
    private let maxRetainedSamples = 3600 // 1-hour graph window at 1s resolution
    // Trim in chunks rather than on every append, so the buffer doesn't
    // shift all 3600 elements every second once it's full.
    private let trimChunk = 300

    private var timer: DispatchSourceTimer?
    private var currentInterval: TimeInterval?
    private let queue = DispatchQueue(label: "com.netpulse.trafficsampler", qos: .utility)

    // macOS updates an interface's if_data byte counters in batches rather
    // than continuously, so diffing two readings taken too close together
    // often sees no change and reports a false 0 B/s. A sample is only
    // published once enough time has passed since the window's start. The
    // threshold sits slightly under the 1s tick so ordinary timer jitter
    // doesn't push every other sample out to 2s.
    private var windowStart: InterfaceCounterReading?
    private var windowStartName: String?
    private let minimumSampleWindow: TimeInterval = 0.85

    // Once Auto mode has locked onto a real primary interface, keep using it
    // across transient nil results from primaryInterfaceProvider, instead of
    // bouncing onto the full-interface aggregate (a different counter
    // baseline, which reset the window and clamped to a false 0).
    private var lastKnownPrimaryName: String?

    var interfaceSelection: InterfaceSelectionMode = .auto

    /// Pausing genuinely stops the timer. It used to keep firing and just
    /// return early, so "paused" still woke the CPU on every tick.
    var isPaused: Bool = false {
        didSet {
            guard isPaused != oldValue else { return }
            if isPaused {
                cancelTimer()
            } else if let interval = currentInterval {
                scheduleTimer(interval: interval)
            }
        }
    }

    /// Supplies the BSD name of the currently-primary interface (the same one
    /// InterfaceMonitor shows as "Interface" in the popup) for Auto mode.
    var primaryInterfaceProvider: (() -> String?)?

    var onSample: ((NetworkSample) -> Void)?

    func start(interval: TimeInterval) {
        currentInterval = max(interval, Self.minimumTickInterval)
        windowStart = nil
        windowStartName = nil
        guard !isPaused, let interval = currentInterval else { return }
        scheduleTimer(interval: interval)
    }

    func stop() {
        cancelTimer()
    }

    func reschedule(interval: TimeInterval) {
        start(interval: interval)
    }

    func samples(inLast window: TimeInterval) -> [NetworkSample] {
        let cutoff = Date().addingTimeInterval(-window)
        // Samples are appended in time order, so binary-search the cutoff
        // rather than scanning the whole buffer on every render.
        var low = 0
        var high = recentSamples.count
        while low < high {
            let mid = (low + high) / 2
            if recentSamples[mid].timestamp < cutoff { low = mid + 1 } else { high = mid }
        }
        return Array(recentSamples[low...])
    }

    // MARK: - Timer

    private func scheduleTimer(interval: TimeInterval) {
        cancelTimer()
        let source = DispatchSource.makeTimerSource(queue: queue)
        // A generous leeway lets macOS coalesce this wakeup with others,
        // which is the single biggest energy lever for a periodic timer.
        let leewayMs = max(100, Int(interval * 1000 * 0.1))
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(leewayMs))
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        timer = source
    }

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Sampling

    private func tick() {
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

        // The tracked interface changed — reset the baseline rather than
        // diffing across two different counter spaces.
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

        windowStart = currentReading

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.recentSamples.append(sample)
            if self.recentSamples.count > self.maxRetainedSamples + self.trimChunk {
                self.recentSamples.removeFirst(self.recentSamples.count - self.maxRetainedSamples)
            }
            self.onSample?(sample)
        }
    }
}
