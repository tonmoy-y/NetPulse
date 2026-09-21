<p align="center">
  <img src="Brand/Logo/netpulse-mark-256.png" width="96" height="96" alt="NetPulse logo" />
</p>

<h1 align="center">NetPulse</h1>

<p align="center"><strong>Lightweight, real-time, privacy-first network monitoring for the macOS menu bar.</strong></p>

<p align="center">
  ↓ 2.4 MB/s&nbsp;&nbsp;↑ 384 KB/s
</p>

---

**Author:** Tonmoy Sarker Sourav

NetPulse shows your Mac's live download and upload throughput directly in
the menu bar, with a compact native popup for graphs, statistics, latency,
data usage, and alerts — built with SwiftUI and AppKit, with no Electron, no
webviews, and no background telemetry.

## Features

- **Live menu bar speed** — real download/upload throughput read straight from interface byte counters (`getifaddrs`), not simulated. Configurable refresh interval from 100 ms to 5 s.
- **Six menu bar display modes** — inline arrows, stacked arrows, lettered (`D`/`U`), value-first, download-only, upload-only — plus units, decimal places, separator, and compact mode.
- **Interface awareness** — auto-detects Wi-Fi, Ethernet, Thunderbolt/USB Ethernet, and VPN interfaces; Auto mode intelligently prefers a wired link over Wi-Fi over VPN tunnels; manual pinning to a specific interface is also supported.
- **Compact popup** — real-time overview, a Swift Charts graph (30s – 1h windows, toggle download/upload), and a full statistics view (current/average/peak/session/lifetime totals).
- **Data usage** — Today / This Week / This Month rollups, persisted locally, clearly labeled as *estimated from observed interface counters*, not carrier billing data.
- **Latency & network quality** — gentle, single-packet ICMP polling (1.1.1.1 / 8.8.8.8 / 9.9.9.9 / custom) with average/min/max/packet-loss, feeding a configurable Excellent → Poor quality indicator derived from multiple signals, not one sample.
- **Connection history** — tracks connect/disconnect events, disconnect count, and downtime.
- **Alerts** — native macOS notifications for download/upload thresholds, latency, packet loss, and connection loss/restore, each with its own cooldown so you're never spammed.
- **Manual speed test** — never runs automatically; measures against Cloudflare's public, documented speed-test endpoints and clearly discloses that it consumes bandwidth.
- **Optional public IP lookup** — off by default, one external request only when you explicitly enable it.

## Privacy

NetPulse works completely offline for throughput monitoring, interface
detection, local IP info, statistics, graphs, and data usage. There is:

- **No analytics, no telemetry, no tracking, no advertising, no accounts, no cloud backend.**
- Two features make an external network request, and both are opt-in and clearly disclosed in Settings → Privacy: **public IP lookup** (off by default) and the **manual speed test** (never automatic).

## Screenshots

_Add screenshots here once you've built the app — e.g. `docs/screenshot-menubar.png`, `docs/screenshot-popup.png`, `docs/screenshot-settings.png`._

## Installation

### Homebrew (once released)

```bash
brew install --cask netpulse
```

A cask definition is included at [`Homebrew/netpulse.rb`](Homebrew/netpulse.rb) — nothing is published automatically; you publish it to a tap when you're ready.

### Build from source

See [Build Instructions](#build-instructions) below.

## Usage

- Click the menu bar item to open the popup: **Overview**, **Graph**, and **Statistics** tabs.
- Open **Settings** (via the popup footer or ⌘,) to customize the menu bar display, interface selection, graph window, data usage retention, latency target, alert thresholds, and privacy options.
- The app never shows a Dock icon — it lives entirely in the menu bar (`LSUIElement`).

## Configuration highlights

| Setting | Where |
|---|---|
| Refresh interval (100 ms – 5 s) | Settings → General |
| Menu bar display mode & formatting | Settings → Menu Bar |
| Interface selection (Auto / specific) | Settings → Network |
| Graph time window (30 s – 1 h) | Settings → Graph |
| Data usage retention | Settings → Data Usage |
| Ping target & interval | Settings → Latency |
| Alert thresholds & cooldowns | Settings → Alerts |
| Public IP lookup / speed test toggle | Settings → Privacy |

## Architecture

```
NetPulseCore/            Pure Swift package: models, formatters, statistics
                          accumulators, alert/quality logic — no AppKit
                          dependency, fully unit-tested with `swift test`.
NetPulse/
├── App/                  App entry point, AppDelegate, AppState (coordinator)
├── MenuBar/              Menu bar label view
├── Core/
│   ├── NetworkMonitor/   getifaddrs-based counter reading + sampling
│   ├── InterfaceMonitor/ Interface discovery, NWPathMonitor connection state
│   ├── LatencyMonitor/   ICMP round-trip measurement
│   ├── DataUsage/        Day-bucketed usage ledger + rollups
│   ├── Persistence/      UserDefaults + JSON file storage
│   ├── SpeedTest/        Manual, user-initiated bandwidth test
│   ├── Alerts/           Threshold evaluation + UNUserNotificationCenter
│   └── ConnectionHistory/Connect/disconnect event log
├── Services/             PublicIPService (opt-in)
├── Views/                Overview, Graph, Statistics, Settings, shared UI
├── Utilities/            Brand colors/typography, login item, window routing
└── Resources/            Info.plist, entitlements, asset catalog
Brand/                    Full brand system (logo, colors, typography, docs)
Homebrew/                 Cask definition
scripts/                  Icon/asset generation
```

`AppState` is the single coordinator: it owns every monitor/store, applies
settings changes reactively, and is the only thing views talk to.

## Testing

Pure logic — byte formatting, throughput calculation, statistics
accumulation, latency stats, data usage aggregation, alert-rule triggering,
network quality scoring, and menu bar formatting — lives in `NetPulseCore`
and is covered by `NetPulseCoreTests`:

```bash
cd NetPulseCore
swift test
```

> This was written and organized on a machine with only the Xcode Command
> Line Tools installed (no full Xcode, and the CLT's own Swift Package
> Manager toolchain was non-functional even for a trivial throwaway
> package), so these tests could not be executed in this environment. Run
> `swift test` yourself once you have a working Swift toolchain — the suite
> covers the edge cases called out in the spec (zero bytes, very high
> throughput, counter resets/interface disappearance, all-packets-lost, ring
> buffer capping).

## Build Instructions

1. **Install [XcodeGen](https://github.com/yonaskolb/XcodeGen)** (generates `NetPulse.xcodeproj` from `project.yml` — more reliable than a hand-edited project file, and how this repo's `.xcodeproj` was produced):
   ```bash
   brew install xcodegen
   ```
2. **Generate the project** (re-run this any time you add/remove files or edit `project.yml`):
   ```bash
   xcodegen generate
   ```
3. **Open in Xcode:**
   ```bash
   open NetPulse.xcodeproj
   ```
4. Select the **NetPulse** scheme and **Run** (⌘R). Requires Xcode 15+ and macOS 13 Ventura or newer.

### Release build

```bash
xcodebuild -project NetPulse.xcodeproj -scheme NetPulse -configuration Release build
```

### Archive & notarize (Developer ID)

NetPulse is **not** sandboxed (it reads interface counters via `getifaddrs`
and shells out to the system `/sbin/ping`, neither permitted under App
Sandbox), so it's distributed via Developer ID, not the Mac App Store.
`ENABLE_HARDENED_RUNTIME` is already set to `YES` in `project.yml`.

```bash
xcodebuild -project NetPulse.xcodeproj -scheme NetPulse -configuration Release \
  -archivePath build/NetPulse.xcarchive archive

xcodebuild -exportArchive -archivePath build/NetPulse.xcarchive \
  -exportPath build/export -exportOptionsPlist ExportOptions.plist

xcrun notarytool submit build/export/NetPulse.app.zip \
  --apple-id "you@example.com" --team-id TEAMID --password "app-specific-password" --wait

xcrun stapler staple build/export/NetPulse.app
```

You'll need to supply your own Developer ID signing identity and team ID —
none are hardcoded in this project.

### DMG creation

```bash
hdiutil create -volname "NetPulse" -srcfolder build/export/NetPulse.app \
  -ov -format UDZO NetPulse-1.0.0.dmg
```

## License

[MIT](LICENSE) — © 2026 Tonmoy Sarker Sourav
