# NetPulse Brand Guide

**Author:** Tonmoy Sarker Sourav

## 1. Product name

**NetPulse** — used consistently as the app name, bundle display name, About
page title, README title, and package/DMG name. Never abbreviated or
re-branded elsewhere in the project.

## 2. Brand concept

NetPulse exists to make one thing instantly legible: *what is happening on
your network, right now.* The identity is built around the idea of a
**pulse** — a live, continuous signal — rather than a static gauge or a
generic "speedometer" cliché. It should read as precise, technical, and
calm: a tool an engineer trusts, not a flashy dashboard.

Personality: network · speed · real-time · reliability · precision ·
lightweight · modern engineering · macOS-native quality.

Explicitly avoided: gaming aesthetics, cyberpunk/neon styling, cartoonish
icons, gradients-for-their-own-sake, and anything resembling an existing
menu-bar monitoring tool's silhouette or color scheme.

## 3. Logo concept

The NetPulse mark (`NetPulseMark.swift`, `Brand/Logo/`) is an original
geometric waveform: a single continuous line that steps up and down like a
heartbeat trace or an oscilloscope reading. It reads simultaneously as:

- A **pulse** (the product name, literally)
- **Data in motion** through a connection
- A visual echo of the ↓ / ↑ arrows used everywhere else in the product

It is not a Wi-Fi glyph, not Apple's network symbols, and not traced from any
existing monitoring app's icon. It is a single stroked polyline, which is
also why it stays legible at 16×16.

## 4. Menu bar visual language

Default menu bar output:

```
↓ 2.4 MB/s  ↑ 384 KB/s
```

Rules:
- Never show CPU / RAM / disk / battery / GPU in the default menu bar — NetPulse is a network monitor only.
- A small colored dot only appears when the connection is poor or offline — normal operation stays silent, with no persistent color coding.
- Numbers are always monospaced-digit to prevent the menu bar from "jittering" as values change width.

## 5. Download / upload visual language

Consistent across menu bar, popup, graph, statistics, and settings:
- **Download** → `netPulseDownload` (teal), down-arrow
- **Upload** → `netPulseUpload` (amber/coral), up-arrow

Cool vs. warm keeps the two instantly distinguishable without relying on the
arrow glyph alone (accessibility: color is never the *only* signal — labels
and arrows are always present too).

## 6. Network status states

| State | Color token | Meaning |
|---|---|---|
| Connected / Excellent / Good | `netPulseSuccess` | Normal operation, shown only as a label, not a persistent badge |
| Fair / Poor | `netPulseWarning` / `netPulseError` | Surfaced via the quality badge and an optional menu bar dot |
| Offline | `netPulseTextMuted` + `netPulseError` accents | Disconnected state, shown explicitly with text, never color alone |

## 7. Empty states

Every empty state is written for its specific context (see
`EmptyStateView.swift`), e.g. *"No active network interface detected"*
rather than a generic "No data available."

## 8. Asset organization

```
Brand/
├── Logo/            generated brand mark PNGs (16 – 1024px)
├── AppIcon/          app icon usage notes
├── Colors/           Palette.md — full color spec
├── Typography/       Typography.md — type scale
├── Icons/            reserved for future custom iconography
└── Documentation/    this file
```

## 9. Originality statement

All colors, the logo geometry, the typography scale, and the UI layout in
this repository were designed from scratch for NetPulse. No assets, code, or
branding were copied from NetBar, Stats, iStat Menus, NetSpeedBar, or any
other existing product.
