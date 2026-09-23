import Foundation
import Network
import SystemConfiguration
import Combine
import NetPulseCore

/// Discovers available network interfaces (Wi-Fi, Ethernet, VPN, etc.), their
/// addressing info, and overall path/connection state using Apple's Network
/// and SystemConfiguration frameworks.
final class InterfaceMonitor: ObservableObject {
    @Published private(set) var interfaces: [NetworkInterfaceInfo] = []
    @Published private(set) var primaryInterface: NetworkInterfaceInfo?
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isVPNActive: Bool = false

    private let pathMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.netpulse.interfacemonitor", qos: .utility)
    private var store: SCDynamicStore?
    private var fallbackTimer: Timer?

    /// Interface changes are picked up from system notifications — the
    /// configd dynamic store and NWPathMonitor — rather than by polling. This
    /// used to re-scan every 5 seconds on the main thread and open a fresh
    /// configd session each time, whether or not anything had changed. The
    /// slow fallback scan only covers anything the notifications miss.
    private let fallbackInterval: TimeInterval = 60

    func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let vpn = path.usesInterfaceType(.other) && path.availableInterfaces.contains { $0.type == .other }
            DispatchQueue.main.async {
                if self.isConnected != connected { self.isConnected = connected }
                if self.isVPNActive != vpn { self.isVPNActive = vpn }
            }
            self.refresh()
        }
        pathMonitor.start(queue: queue)
        startDynamicStoreNotifications()
        refresh()

        let timer = Timer(timeInterval: fallbackInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        // Lets macOS coalesce this wakeup with others instead of firing on
        // the exact second.
        timer.tolerance = fallbackInterval * 0.25
        RunLoop.main.add(timer, forMode: .common)
        fallbackTimer = timer
    }

    func stop() {
        pathMonitor.cancel()
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        if let store {
            SCDynamicStoreSetDispatchQueue(store, nil)
        }
    }

    /// Re-scans interfaces off the main thread and publishes only what
    /// actually changed — every @Published assignment notifies observers
    /// even when the value is identical.
    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let discovered = Self.discoverInterfaces()
            let systemPrimaryName = self.systemPrimaryInterfaceBSDName()

            // Prefer the interface macOS itself routes default traffic
            // through (the same source System Settings > Network and
            // `scutil --nwi` use) over our own isUp/kind heuristic, which
            // picks phantom always-up interfaces — typically a Thunderbolt
            // Bridge member kept up with a link-local IPv6 address and no
            // real traffic. Sampling that interface showed a near-constant
            // 0 B/s while fully connected. The heuristic is only a fallback
            // for when there's no default route at all.
            let primary: NetworkInterfaceInfo?
            if let name = systemPrimaryName, let match = discovered.first(where: { $0.bsdName == name }) {
                primary = match
            } else {
                primary = PrimaryInterfaceSelector.choose(from: discovered)
            }

            DispatchQueue.main.async {
                if self.interfaces != discovered { self.interfaces = discovered }
                if self.primaryInterface != primary { self.primaryInterface = primary }
            }
        }
    }

    // MARK: - System configuration store

    /// Subscribes to configd for the keys that change when an interface
    /// comes up or down, gains or loses an address, or the default route
    /// moves. Callbacks arrive on `queue`.
    private func startDynamicStoreNotifications() {
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: SCDynamicStoreCallBack = { _, _, info in
            guard let info else { return }
            Unmanaged<InterfaceMonitor>.fromOpaque(info).takeUnretainedValue().refresh()
        }
        guard let store = SCDynamicStoreCreate(nil, "com.netpulse.interfacemonitor" as CFString, callback, &context) else {
            return
        }

        let keys = ["State:/Network/Global/IPv4", "State:/Network/Global/IPv6"] as CFArray
        let patterns = [
            "State:/Network/Interface/[^/]+/Link",
            "State:/Network/Interface/[^/]+/IPv4",
            "State:/Network/Interface/[^/]+/IPv6"
        ] as CFArray
        SCDynamicStoreSetNotificationKeys(store, keys, patterns)
        SCDynamicStoreSetDispatchQueue(store, queue)
        self.store = store
    }

    /// Reads the BSD name of the interface macOS is actually using for its
    /// default route. Reuses the long-lived store rather than opening a new
    /// configd session on every refresh.
    private func systemPrimaryInterfaceBSDName() -> String? {
        let session = store ?? SCDynamicStoreCreate(nil, "com.netpulse.interfacemonitor.query" as CFString, nil, nil)
        guard let session,
              let global = SCDynamicStoreCopyValue(session, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }
        return global["PrimaryInterface"] as? String
    }

    // MARK: - Discovery

    private static func discoverInterfaces() -> [NetworkInterfaceInfo] {
        var addressesByName: [String: (ipv4: String?, ipv6: String?)] = [:]
        var flagsByName: [String: (isUp: Bool, isRunning: Bool)] = [:]
        // Collected in this same pass. Looking each one up separately meant
        // a fresh full getifaddrs() walk per interface — O(n²) syscalls
        // every refresh, repeated every 5 seconds for the app's lifetime.
        var macByName: [String: String] = [:]

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return [] }
        defer { freeifaddrs(ifaddrPtr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let addr = current.pointee
            let name = String(cString: addr.ifa_name)
            let family = addr.ifa_addr.pointee.sa_family

            var entry = addressesByName[name] ?? (nil, nil)
            if family == UInt8(AF_INET) {
                entry.ipv4 = ipAddressString(addr.ifa_addr, family: AF_INET)
            } else if family == UInt8(AF_INET6) {
                entry.ipv6 = ipAddressString(addr.ifa_addr, family: AF_INET6)
            } else if family == UInt8(AF_LINK), let mac = macAddress(from: addr.ifa_addr) {
                macByName[name] = mac
            }
            addressesByName[name] = entry

            flagsByName[name] = (
                isUp: (Int32(addr.ifa_flags) & IFF_UP) != 0,
                isRunning: (Int32(addr.ifa_flags) & IFF_RUNNING) != 0
            )
        }

        let bsdOrder = flagsByName.keys.sorted()
        var results: [NetworkInterfaceInfo] = []

        for name in bsdOrder {
            guard !name.hasPrefix("lo") else { continue }
            let flags = flagsByName[name] ?? (false, false)
            let addresses = addressesByName[name] ?? (nil, nil)
            let kind = classify(bsdName: name)
            let displayName = friendlyName(bsdName: name, kind: kind)

            results.append(NetworkInterfaceInfo(
                bsdName: name,
                displayName: displayName,
                kind: kind,
                isActive: flags.isUp && flags.isRunning && (addresses.ipv4 != nil || addresses.ipv6 != nil),
                isUp: flags.isUp,
                linkSpeedMbps: nil,
                macAddress: macByName[name],
                ipv4: addresses.ipv4,
                ipv6: addresses.ipv6
            ))
        }

        return results
    }

    private static func classify(bsdName: String) -> NetworkInterfaceKind {
        switch true {
        case bsdName.hasPrefix("en"): return bsdName == "en0" ? .wifi : .ethernet
        case bsdName.hasPrefix("utun"), bsdName.hasPrefix("ppp"), bsdName.hasPrefix("ipsec"): return .vpn
        case bsdName.hasPrefix("pdp_ip"), bsdName.hasPrefix("cellular"): return .cellular
        case bsdName.hasPrefix("lo"): return .loopback
        default: return .other
        }
    }

    private static func friendlyName(bsdName: String, kind: NetworkInterfaceKind) -> String {
        "\(kind.rawValue) (\(bsdName))"
    }

    private static func ipAddressString(_ sockaddrPtr: UnsafeMutablePointer<sockaddr>, family: Int32) -> String? {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(sockaddrPtr, socklen_t(sockaddrPtr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
        guard result == 0 else { return nil }
        let address = String(cString: host)
        // Strip zone-id suffix from link-local IPv6 addresses (e.g. "%en0").
        return address.split(separator: "%").first.map(String.init)
    }

    /// Reads the hardware address out of an AF_LINK sockaddr already in
    /// hand, so interface discovery can collect MACs during its single
    /// getifaddrs() walk rather than re-walking the list per interface.
    private static func macAddress(from sockaddrPtr: UnsafeMutablePointer<sockaddr>) -> String? {
        var sdl = UnsafeRawPointer(sockaddrPtr).assumingMemoryBound(to: sockaddr_dl.self).pointee
        guard Int(sdl.sdl_alen) == 6 else { return nil }

        let macBytes = withUnsafePointer(to: &sdl.sdl_data) { ptr -> [UInt8] in
            ptr.withMemoryRebound(to: UInt8.self, capacity: 12) { base in
                let offset = Int(sdl.sdl_nlen)
                return (0..<6).map { base[offset + $0] }
            }
        }
        return macBytes.map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}
