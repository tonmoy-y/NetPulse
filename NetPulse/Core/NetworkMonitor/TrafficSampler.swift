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
            raw = InterfaceCounterReader.aggregate(allCounters)
            selectedName = "auto"
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
