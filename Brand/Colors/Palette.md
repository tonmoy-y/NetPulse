# NetPulse Color System

All tokens are defined for both Light and Dark Mode. Swift source of truth:
`NetPulse/Utilities/Color+Brand.swift`.

| Token | Role | Light HEX | Light RGB | Dark HEX | Dark RGB |
|---|---|---|---|---|---|
| `netPulsePrimary` | Brand identity, primary actions | `#12B8AF` | 18, 184, 175 | `#2DD4CE` | 45, 212, 206 |
| `netPulseSecondary` | Secondary emphasis | `#4A5FE8` | 74, 95, 232 | `#6B7CFF` | 107, 124, 255 |
| `netPulseDownload` | Download metric, graph line | `#14B8A6` | 20, 184, 166 | `#2DD4C4` | 45, 212, 196 |
| `netPulseUpload` | Upload metric, graph line | `#F2762E` | 242, 118, 46 | `#FF9A52` | 255, 154, 82 |
| `netPulseSuccess` | Connected / good quality | `#21A366` | 33, 163, 102 | `#3DDB8A` | 61, 219, 138 |
| `netPulseWarning` | Fair quality, soft alerts | `#E8A33D` | 232, 163, 61 | `#FFC059` | 255, 192, 89 |
| `netPulseError` | Poor / disconnected | `#E24B4B` | 226, 75, 75 | `#FF6B6B` | 255, 107, 107 |
| `netPulseSurface` | Card / panel background | `#FFFFFF` | 255, 255, 255 | `#242426` | 36, 36, 38 |
| `netPulseBorder` | Hairlines, dividers | `#E5E5EA` | 229, 229, 234 | `#38383A` | 56, 56, 58 |
| `netPulseTextSecondary` | Secondary text | `#6E6E72` | 110, 110, 114 | `#98989D` | 152, 152, 157 |
| `netPulseTextMuted` | Captions, disabled | `#AEAEB2` | 174, 174, 178 | `#636366` | 99, 99, 102 |

## Usage rules

- Accent colors are reserved for download/upload metrics, network state, graphs, and alerts — never used decoratively.
- Text and connection-state meaning are never conveyed by color alone; every colored indicator is paired with a label or icon.
- Background/surface colors defer to macOS system materials (`.regularMaterial`, `NSVisualEffectView`) where appropriate rather than hardcoding opaque panels everywhere.

## Swift definitions

```swift
extension Color {
    static let netPulsePrimary = Color.dynamic(
        light: NSColor(red: 0.071, green: 0.722, blue: 0.686, alpha: 1),
        dark:  NSColor(red: 0.176, green: 0.831, blue: 0.808, alpha: 1)
    )
    // ...full set in NetPulse/Utilities/Color+Brand.swift
}
```
