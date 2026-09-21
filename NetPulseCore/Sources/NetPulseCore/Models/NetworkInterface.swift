import Foundation

public enum NetworkInterfaceKind: String, Codable, CaseIterable {
    case wifi = "Wi-Fi"
    case ethernet = "Ethernet"
    case thunderboltEthernet = "Thunderbolt Ethernet"
    case usbEthernet = "USB Ethernet"
    case vpn = "VPN"
    case cellular = "Cellular"
    case loopback = "Loopback"
    case other = "Other"
}

public enum InterfaceSelectionMode: Codable, Equatable {
    case auto
    case specific(bsdName: String)
}

public struct NetworkInterfaceInfo: Codable, Equatable, Identifiable {
    public var id: String { bsdName }
    public let bsdName: String          // e.g. "en0"
    public let displayName: String      // e.g. "Wi-Fi"
    public let kind: NetworkInterfaceKind
    public let isActive: Bool
    public let isUp: Bool
    public let linkSpeedMbps: Int?
    public let macAddress: String?
    public let ipv4: String?
    public let ipv6: String?

    public init(bsdName: String, displayName: String, kind: NetworkInterfaceKind, isActive: Bool, isUp: Bool,
                linkSpeedMbps: Int? = nil, macAddress: String? = nil, ipv4: String? = nil, ipv6: String? = nil) {
        self.bsdName = bsdName
        self.displayName = displayName
        self.kind = kind
        self.isActive = isActive
        self.isUp = isUp
        self.linkSpeedMbps = linkSpeedMbps
        self.macAddress = macAddress
        self.ipv4 = ipv4
        self.ipv6 = ipv6
    }
}

/// Chooses the "primary" interface out of a candidate list when Auto mode is active:
/// prefer active + up interfaces, then rank by kind (Ethernet-family over Wi-Fi over VPN/other).
public enum PrimaryInterfaceSelector {
    private static let priority: [NetworkInterfaceKind: Int] = [
        .thunderboltEthernet: 0,
        .ethernet: 1,
        .usbEthernet: 2,
        .wifi: 3,
        .vpn: 4,
        .cellular: 5,
        .other: 6,
        .loopback: 7
    ]

    public static func choose(from interfaces: [NetworkInterfaceInfo]) -> NetworkInterfaceInfo? {
        interfaces
            .filter { $0.isUp && $0.kind != .loopback }
            .sorted { a, b in
                if a.isActive != b.isActive { return a.isActive && !b.isActive }
                let pa = priority[a.kind] ?? 99
                let pb = priority[b.kind] ?? 99
                return pa < pb
            }
            .first
    }
}
