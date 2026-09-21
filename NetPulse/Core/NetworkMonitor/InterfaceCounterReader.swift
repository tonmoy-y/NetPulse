import Foundation
import NetPulseCore

/// Reads raw cumulative rx/tx byte counters straight from the BSD network
/// interface list via `getifaddrs`, the same low-level source macOS itself
/// uses for `netstat -ib`. No sampling, no simulation.
enum InterfaceCounterReader {

    struct RawCounters {
        let bsdName: String
        let bytesReceived: UInt64
        let bytesSent: UInt64
        let isUp: Bool
    }

    /// Returns per-interface counters for every non-loopback link-layer interface.
    static func readAll() -> [RawCounters] {
        var results: [RawCounters] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return results }
        defer { freeifaddrs(ifaddrPtr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }

            let addr = current.pointee
            guard addr.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            guard let data = addr.ifa_data else { continue }

            let name = String(cString: addr.ifa_name)
            let networkData = data.withMemoryRebound(to: if_data.self, capacity: 1) { $0.pointee }
            let isUp = (Int32(addr.ifa_flags) & IFF_UP) != 0

            results.append(RawCounters(
                bsdName: name,
                bytesReceived: UInt64(networkData.ifi_ibytes),
                bytesSent: UInt64(networkData.ifi_obytes),
                isUp: isUp
            ))
        }
        return results
    }

    /// Aggregates counters across every active, non-loopback, non-VM interface —
    /// used for the "Auto" total view when no single interface is pinned.
    static func aggregate(_ counters: [RawCounters], excluding excludedPrefixes: [String] = ["lo", "gif", "stf", "utun", "awdl", "llw", "bridge", "ap"]) -> RawCounters {
        let filtered = counters.filter { c in
            !excludedPrefixes.contains { c.bsdName.hasPrefix($0) }
        }
        let rx = filtered.reduce(UInt64(0)) { $0 + $1.bytesReceived }
        let tx = filtered.reduce(UInt64(0)) { $0 + $1.bytesSent }
        return RawCounters(bsdName: "auto", bytesReceived: rx, bytesSent: tx, isUp: filtered.contains { $0.isUp })
    }
}
