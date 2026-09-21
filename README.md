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

**Author:** Tonmoy Sarker Sourav

NetPulse is **free and open source** (MIT licensed — see [LICENSE](LICENSE)).
It shows your Mac's live download and upload throughput directly in the menu
bar, with a compact native popup for graphs, statistics, latency, data
usage, and alerts — built with SwiftUI and AppKit, with no Electron, no
webviews, and no background telemetry. All source, the build pipeline, and
the release process are public in this repository; nothing about how it's
built or what it sends over the network is hidden.

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
- **Update checks** — checks GitHub Releases for a newer version (a single anonymous request, no analytics), automatically on launch by default or on demand from Settings → General; it only tells you a new version exists and links to it, it never downloads or installs anything itself. Can be turned off entirely.

## Privacy

NetPulse works completely offline for throughput monitoring, interface
detection, local IP info, statistics, graphs, and data usage. There is:

- **No analytics, no telemetry, no tracking, no advertising, no accounts, no cloud backend.**
- Two features make an external network request, and both are opt-in and clearly disclosed in Settings → Privacy: **public IP lookup** (off by default) and the **manual speed test** (never automatic).

## Screenshots

_Not included yet. [v1.0.1](https://github.com/tonmoy-y/NetPulse/releases/tag/v1.0.1) has actually been installed and launched (via the real Homebrew cask) and confirmed to run without crashing, via process/log inspection — but that verification had no Accessibility/screen-recording access to interact with or screenshot the UI itself. Install it (see below), then drop images in `docs/` (e.g. `docs/screenshot-menubar.png`, `docs/screenshot-popup.png`, `docs/screenshot-settings.png`) and reference them here._

## Installation

### Option A — Homebrew (recommended — one command, no Xcode)

```bash
brew tap tonmoy-y/netpulse
brew install --cask netpulse
```

This installs from the [tonmoy-y/homebrew-netpulse](https://github.com/tonmoy-y/homebrew-netpulse) tap, which is real and live — it points at the actual [v1.0.1 release DMG](https://github.com/tonmoy-y/NetPulse/releases/tag/v1.0.1) with its real checksum, built by this repo's own CI, and was verified end-to-end (`brew tap` → `brew install --cask netpulse` → app launched and confirmed running via process/log inspection) before being documented here. The cask also clears the Gatekeeper quarantine flag automatically, so unlike a manual `.dmg` install there's no right-click-to-open step needed.

> **If you installed before this note was added and hit "Invalid cask" / "undefined local variable or method 'appdir'":** that was a real regression in an earlier commit's cask, now fixed. Run `brew update`, then `brew upgrade --cask netpulse` (or `brew untap tonmoy-y/netpulse && brew tap tonmoy-y/netpulse && brew install --cask netpulse` for a clean slate) to pick up the fix — Homebrew taps don't auto-refresh without `brew update`.

> If your Homebrew shows `Refusing to load cask ... from untrusted tap` (a newer Homebrew tap-trust safeguard for third-party taps), run `brew trust --cask tonmoy-y/netpulse/netpulse` once and re-run the install command.

### Option B — Download the .dmg directly

1. Go to **[Releases](https://github.com/tonmoy-y/NetPulse/releases/latest)** and download `NetPulse-*.dmg`.
2. Open the `.dmg` and drag **NetPulse.app** into **Applications**.
3. **First launch only:** NetPulse is ad-hoc signed, not notarized with a paid Apple Developer ID, so Gatekeeper will say it "cannot be verified." Right-click (Control-click) **NetPulse.app** → **Open** → **Open** again. You only need to do this once; after that it opens normally, including via Launchpad/Spotlight.
4. NetPulse appears in the menu bar — it has **no Dock icon** and **no window** to look for.

> Genuinely warning-free (no right-click-to-open step at all, for *this* path) requires signing with a **paid Apple Developer ID** ($99/year) and notarizing with `notarytool` — see [Archive & notarize](#archive--notarize-developer-id) if you have one. Without it, this one-time step is unavoidable for any indie-built Mac app via direct `.dmg`, not specific to NetPulse — which is exactly why Option A exists.

### Option C — Build from source

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

> **If Xcode complains "Signing for 'NetPulse' requires a development team":**
> `project.yml` ships with ad-hoc signing (`CODE_SIGN_IDENTITY: "-"`) specifically so a fresh clone builds and runs immediately with no Apple ID configured. If you still hit this, you likely have a stale generated project — delete `NetPulse.xcodeproj` and re-run `xcodegen generate`. (If you *want* Automatic signing with your own Apple ID instead, change it in Xcode's Signing & Capabilities tab after generating, or edit the `CODE_SIGN_*` keys in `project.yml`.)

### Release build

```bash
xcodebuild -project NetPulse.xcodeproj -scheme NetPulse -configuration Release build
```

### Archive & notarize (Developer ID) — optional

**Skip this entirely unless you specifically want a Gatekeeper-clean build.**
It's not required to build, run, or distribute NetPulse — the CI pipeline
above (and everything in this README's main install path) already produces
a working ad-hoc-signed `.dmg` with no Developer ID needed. This section
only matters if you own a paid Apple Developer ID and want to remove the
one-time right-click → Open step for people who download the `.dmg`
directly.

NetPulse is **not** sandboxed (it reads interface counters via `getifaddrs`
and shells out to the system `/sbin/ping`, neither permitted under App
Sandbox), so if you do notarize it, it's distributed via Developer ID, not
the Mac App Store. `ENABLE_HARDENED_RUNTIME` is already set to `YES` in
`project.yml`.

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

### Publishing a release

The easiest path — and the one **Option A** above depends on — is automated:
[`.github/workflows/release.yml`](.github/workflows/release.yml) runs on a
real macOS GitHub Actions runner (full Xcode, unlike this repo's own dev
environment), runs the `NetPulseCore` test suite, builds an ad-hoc-signed
Release build, packages it as a `.dmg`, and — when triggered by a version
tag — attaches it to a GitHub Release automatically.

```bash
git tag v1.0.2
git push origin v1.0.2
```

That's it; watch the **Actions** tab, and the `.dmg` shows up on the
**Releases** page a few minutes later. You can also trigger a build without
tagging via the workflow's **Run workflow** button (Actions → Build NetPulse
DMG → Run workflow) to get an artifact without publishing a release.

After a new release, update the cask so `brew install --cask netpulse`
picks it up:

1. `shasum -a 256 NetPulse-<version>.dmg` on the new release asset.
2. Bump `version` and `sha256` in both [`Homebrew/netpulse.rb`](Homebrew/netpulse.rb) here (kept as a reference copy) **and** `Casks/netpulse.rb` in [tonmoy-y/homebrew-netpulse](https://github.com/tonmoy-y/homebrew-netpulse) (the actual tap Homebrew reads — clone it, edit, commit, push).

## Contributing

Issues and pull requests are welcome. There's no formal process — open an
issue for bugs or feature ideas, or a PR directly for fixes. A few notes:

- Regenerate the Xcode project after adding/removing files or editing `project.yml`: `xcodegen generate`.
- Pure logic (formatters, statistics, alert/quality evaluation) belongs in `NetPulseCore` with tests (`cd NetPulseCore && swift test`); AppKit/SwiftUI-specific code belongs in the `NetPulse` app target.
- CI (`.github/workflows/release.yml`) runs the real compiler and test suite on every tag push — that's the actual source of truth for "does this build," more than any local environment.

## License

NetPulse is free and open source software, licensed under the [MIT License](LICENSE) — © 2026 Tonmoy Sarker Sourav. Use it, fork it, modify it, redistribute it, for any purpose, with attribution as the license requires.
