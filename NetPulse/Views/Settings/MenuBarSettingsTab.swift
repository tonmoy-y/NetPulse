import SwiftUI
import NetPulseCore

struct MenuBarSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Display Mode") {
                Picker("Mode", selection: $appState.settings.menuBar.mode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Text(preview)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.netPulseBorder.opacity(0.3)))
            }

            Section("Content") {
                Toggle("Show units (KB/s, MB/s…)", isOn: $appState.settings.menuBar.showUnits)
                Toggle("Compact mode", isOn: $appState.settings.menuBar.compact)
                Toggle("Show connection state indicator", isOn: $appState.settings.showConnectionStateInMenuBar)

                Stepper(value: $appState.settings.menuBar.decimalPlaces, in: 0...2) {
                    Text("Decimal places: \(appState.settings.menuBar.decimalPlaces)")
                }

                TextField("Separator", text: $appState.settings.menuBar.separator)
            }
        }
        .formStyle(.grouped)
        .onChange(of: appState.settings.menuBar.compact) { compact in
            if compact {
                appState.settings.menuBar.decimalPlaces = 0
            }
        }
    }

    private var preview: String {
        MenuBarFormatter.format(downloadBps: 2.4 * 1024 * 1024, uploadBps: 384 * 1024, options: appState.settings.menuBar)
    }
}
