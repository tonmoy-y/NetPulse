import SwiftUI
import NetPulseCore

struct NetworkSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Interface") {
                Picker("Monitor", selection: selectionBinding) {
                    Text("Auto (primary active interface)").tag(InterfaceSelectionMode.auto)
                    ForEach(appState.interfaceMonitor.interfaces) { iface in
                        Text(iface.displayName).tag(InterfaceSelectionMode.specific(bsdName: iface.bsdName))
                    }
                }
                Text("Auto mode intelligently prefers a wired connection over Wi-Fi, and Wi-Fi over VPN tunnels.")
                    .font(.netPulseCaption)
                    .foregroundStyle(Color.netPulseTextMuted)
            }

            Section("Detected Interfaces") {
                if appState.interfaceMonitor.interfaces.isEmpty {
                    EmptyStateView(icon: "wifi.slash", title: "No active network interface detected", message: "Connect to Wi-Fi or Ethernet to see interface details here.")
                } else {
                    ForEach(appState.interfaceMonitor.interfaces) { iface in
                        InterfaceRow(iface: iface, isPrimary: iface.bsdName == appState.interfaceMonitor.primaryInterface?.bsdName)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var selectionBinding: Binding<InterfaceSelectionMode> {
        Binding(
            get: { appState.settings.interfaceSelection },
            set: { appState.settings.interfaceSelection = $0 }
        )
    }
}

private struct InterfaceRow: View {
    let iface: NetworkInterfaceInfo
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(iface.displayName).font(.netPulseSettingsLabel)
                if isPrimary {
                    Text("PRIMARY").font(.netPulseCaption).foregroundStyle(Color.netPulsePrimary)
                }
                Spacer()
                Text(iface.isActive ? "Connected" : "Inactive")
                    .font(.netPulseCaption)
                    .foregroundStyle(iface.isActive ? Color.netPulseSuccess : Color.netPulseTextMuted)
            }
            if let ipv4 = iface.ipv4 {
                Text("IPv4: \(ipv4)").font(.netPulseCaption).foregroundStyle(Color.netPulseTextSecondary)
            }
            if let mac = iface.macAddress {
                Text("MAC: \(mac)").font(.netPulseCaption).foregroundStyle(Color.netPulseTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension InterfaceSelectionMode: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .auto: hasher.combine(0)
        case .specific(let name): hasher.combine(1); hasher.combine(name)
        }
    }
}
