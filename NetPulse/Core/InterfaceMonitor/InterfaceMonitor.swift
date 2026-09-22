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
    private let queue = DispatchQueue(label: "com.netpulse.interfacemonitor")
    private var refreshTimer: Timer?

    func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.isVPNActive = path.usesInterfaceType(.other) && path.availableInterfaces.contains { $0.type == .other }
                self.refresh()
            }
        }
        pathMonitor.start(queue: queue)
        refresh()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        pathMonitor.cancel()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        let discovered = Self.discoverInterfaces()
        let systemPrimaryName = Self.systemPrimaryInterfaceBSDName()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.interfaces = discovered

            // Prefer the interface macOS itself is actually routing default
            // traffic through (same source System Settings > Network and
            // `scutil --nwi` use) over our own isUp/kind heuristic. The
            // heuristic alone picks phantom always-up interfaces that carry
            // no real traffic — most commonly a Thunderbolt Bridge member
            // (en1/en2/...), which macOS keeps "up" with a self-assigned
            // link-local IPv6 address purely for peer-to-peer Thunderbolt
            // networking, with zero cables connected and zero real use. That
            // interface satisfied every condition our heuristic checked
            // (isUp, isRunning, has an IPv6 address) and outranked real Wi-Fi
            // by interface-kind priority (Ethernet > Wi-Fi), so throughput
            // was being sampled from an interface that was never carrying
            // the user's actual traffic — showing near-constant 0 B/s while
            // still fully connected. Falls back to the heuristic only if the
            // system has no default route to report (genuinely offline).
            if let name = systemPrimaryName, let match = discovered.first(where: { $0.bsdName == name }) {
                self.primaryInterface = match
            } else {
                self.primaryInterface = PrimaryInterfaceSelector.choose(from: discovered)
            }
        }
    }

    /// Reads the BSD name of the interface macOS is actually using for its
    /// default route, straight from the same SCDynamicStore key
    /// `scutil --nwi` and System Settings > Network read.
    private static func systemPrimaryInterfaceBSDName() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "com.netpulse.interfacemonitor" as CFString, nil, nil) else {
            return nil
        }
        guard let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
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
