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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.interfaces = discovered
            self.primaryInterface = PrimaryInterfaceSelector.choose(from: discovered)
        }
    }

    // MARK: - Discovery

    private static func discoverInterfaces() -> [NetworkInterfaceInfo] {
        var addressesByName: [String: (ipv4: String?, ipv6: String?)] = [:]
        var flagsByName: [String: (isUp: Bool, isRunning: Bool)] = [:]

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
                macAddress: macAddress(bsdName: name),
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

    private static func macAddress(bsdName: String) -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let addr = current.pointee
            guard String(cString: addr.ifa_name) == bsdName, addr.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            guard let dataPtr = addr.ifa_data else { continue }

            let socketAddr = UnsafeRawPointer(addr.ifa_addr).assumingMemoryBound(to: sockaddr_dl.self).pointee
            _ = dataPtr
            var sdl = socketAddr
            let addressLength = Int(sdl.sdl_alen)
            guard addressLength == 6 else { continue }

            let macBytes = withUnsafePointer(to: &sdl.sdl_data) { ptr -> [UInt8] in
                ptr.withMemoryRebound(to: UInt8.self, capacity: 12) { base in
                    let offset = Int(sdl.sdl_nlen)
                    return (0..<6).map { base[offset + $0] }
                }
            }
            return macBytes.map { String(format: "%02x", $0) }.joined(separator: ":")
        }
        return nil
    }
}
