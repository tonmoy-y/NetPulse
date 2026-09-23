<p align="center">
  <img src="Brand/Logo/netpulse-mark-256.png" width="96" height="96" alt="NetPulse logo" />
</p>

<h1 align="center">NetPulse</h1>

<p align="center"><strong>Lightweight, real-time, privacy-first network monitoring for the macOS menu bar.</strong></p>

<p align="center">
  ↓ 2.4 MB/s&nbsp;&nbsp;↑ 384 KB/s
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="https://github.com/tonmoy-y/NetPulse/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/tonmoy-y/NetPulse"></a>
  <a href="https://github.com/tonmoy-y/NetPulse/actions/workflows/release.yml"><img alt="Build status" src="https://github.com/tonmoy-y/NetPulse/actions/workflows/release.yml/badge.svg"></a>
</p>

---

NetPulse shows your Mac's live download and upload throughput directly in
the menu bar, with a compact native popup for graphs, statistics, latency,
data usage, and alerts. Built with SwiftUI and AppKit — no Electron, no
webviews, no telemetry. Free and open source under the MIT license.

**Author:** Tonmoy Sarker Sourav

## Features

- **Live menu bar speed** — real download/upload throughput from interface byte counters, not simulated. Refresh interval configurable from 1 s to 5 s.
- **Six menu bar display modes** — inline arrows, stacked arrows, lettered, value-first, download-only, upload-only, with configurable units/decimals/separator/compact mode.
- **Interface awareness** — auto-detects Wi-Fi, Ethernet, Thunderbolt/USB Ethernet, and VPN interfaces; Auto mode prefers a wired link over Wi-Fi over VPN tunnels, or pin a specific interface manually.
- **Popup with Overview / Graph / Statistics tabs** — live numbers, a Swift Charts graph (30s–1h windows), and current/average/peak/session/lifetime traffic stats.
- **Data usage** — Today / This Week / This Month rollups, persisted locally.
- **Latency & network quality** — gentle single-packet ICMP polling (1.1.1.1 / 8.8.8.8 / 9.9.9.9 / custom, or off) with average/min/max/packet-loss, feeding an Excellent → Poor quality indicator.
- **Connection history** — tracks connect/disconnect events and downtime.
- **Alerts** — native macOS notifications for throughput/latency/packet-loss thresholds and connection loss/restore, each with its own cooldown.
- **Manual speed test** — never automatic; opt-in, against a public speed-test endpoint.
- **Optional public IP lookup** — off by default.
- **Update checks** — checks GitHub Releases for a newer version on launch (togglable), or on demand from Settings → General. Never auto-installs anything.

## Privacy

No analytics, no telemetry, no tracking, no accounts, no cloud backend.
Throughput, interfaces, graphs, and data usage are computed entirely
on-device. The only external requests are opt-in and disclosed in Settings
→ Privacy: **public IP lookup** (off by default) and the **manual speed
test** (never automatic). The update check is a single anonymous request to
GitHub Releases and can be turned off in Settings → General.

## Installation

### Homebrew (recommended)

```bash
brew tap tonmoy-y/netpulse
brew install --cask netpulse
```
or in one line:

```bash
brew install --cask tonmoy-y/netpulse/netpulse
```
Installs from the [tonmoy-y/homebrew-netpulse](https://github.com/tonmoy-y/homebrew-netpulse)
tap and clears the Gatekeeper quarantine flag automatically. If Homebrew
warns about an untrusted tap, run `brew trust --cask tonmoy-y/netpulse/netpulse`
once.

### Download the .dmg

1. Download `NetPulse-*.dmg` from [Releases](https://github.com/tonmoy-y/NetPulse/releases/latest).
2. Drag **NetPulse.app** into **Applications**.
3. First launch only: NetPulse is ad-hoc signed, not notarized, so right-click (Control-click) **NetPulse.app** → **Open** → **Open** once. After that it opens normally.
4. Look for it in the menu bar — there's no Dock icon and no window.

### Build from source

See [Build Instructions](#build-instructions) below.

## Usage

- Click the menu bar item to open the popup: **Overview**, **Graph**, **Statistics**.
- Open **Settings** (popup footer, or ⌘,) to configure everything below.

| Setting | Where |
|---|---|
| Refresh interval, updates | Settings → General |
| Menu bar display mode & formatting | Settings → Menu Bar |
| Interface selection | Settings → Network |
| Graph time window | Settings → Graph |
| Data usage & retention | Settings → Data Usage |
| Ping target & interval | Settings → Latency |
| Alert thresholds & cooldowns | Settings → Alerts |
| Public IP lookup / speed test toggle | Settings → Privacy |

## Architecture

```
NetPulseCore/            Pure Swift package: models, formatters, statistics
                          accumulators, alert/quality logic — no AppKit
                          dependency, unit-tested with `swift test`.
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
├── Services/             PublicIPService (opt-in), UpdateChecker
├── Views/                Overview, Graph, Statistics, Settings, shared UI
├── Utilities/            Brand colors/typography, login item, window routing
└── Resources/            Info.plist, entitlements, asset catalog
Brand/                    Logo, color system, typography documentation
Homebrew/                 Cask definition (reference copy)
scripts/                  Icon/asset generation
```

`AppState` is the single coordinator: it owns every monitor/store, applies
settings changes reactively, and is the only thing views talk to.

## Testing

Pure logic — byte formatting, throughput calculation, statistics
accumulation, latency stats, data usage aggregation, alert triggering,
network quality scoring, menu bar formatting, and version comparison —
lives in `NetPulseCore`:

```bash
cd NetPulseCore
swift test
```

## Build Instructions

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate the project (re-run after editing `project.yml` or adding/removing files): `xcodegen generate`
3. Open and run: `open NetPulse.xcodeproj`, select the **NetPulse** scheme, ⌘R.

Requires Xcode 15+ and macOS 13 Ventura or newer. Builds are ad-hoc signed
by default (`CODE_SIGN_IDENTITY: "-"` in `project.yml`), so no Apple ID is
needed to build and run locally.

```bash
# Release build
xcodebuild -project NetPulse.xcodeproj -scheme NetPulse -configuration Release build
```

### Notarizing (optional)

Not required to build, run, or distribute NetPulse. Only relevant if you
have a paid Apple Developer ID and want to remove the one-time right-click
→ Open step for people downloading the `.dmg` directly:

```bash
xcodebuild -project NetPulse.xcodeproj -scheme NetPulse -configuration Release \
  -archivePath build/NetPulse.xcarchive archive
xcodebuild -exportArchive -archivePath build/NetPulse.xcarchive \
  -exportPath build/export -exportOptionsPlist ExportOptions.plist
xcrun notarytool submit build/export/NetPulse.app.zip \
  --apple-id "you@example.com" --team-id TEAMID --password "app-specific-password" --wait
xcrun stapler staple build/export/NetPulse.app
```

### Publishing a release

Tagging triggers [`.github/workflows/release.yml`](.github/workflows/release.yml),
which builds, tests, packages a `.dmg`, and attaches it to a GitHub Release:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Then update the Homebrew cask: `shasum -a 256` the new `.dmg`, and bump
`version`/`sha256` in both [`Homebrew/netpulse.rb`](Homebrew/netpulse.rb)
(reference copy) and `Casks/netpulse.rb` in
[tonmoy-y/homebrew-netpulse](https://github.com/tonmoy-y/homebrew-netpulse)
(the tap Homebrew actually reads).

## Contributing

Issues and pull requests are welcome. Pure logic belongs in `NetPulseCore`
with tests; AppKit/SwiftUI code belongs in the `NetPulse` app target.
Regenerate the Xcode project (`xcodegen generate`) after adding/removing
files.

## License

[MIT](LICENSE) — © 2026 Tonmoy Sarker Sourav
