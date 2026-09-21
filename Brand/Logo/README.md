# NetPulse Logo

The mark is a single stroked polyline that steps up and down like a pulse /
oscilloscope trace — see `Brand/Documentation/Branding.md` §3 for the full
concept rationale.

- **Swift source of truth:** `NetPulse/Views/Shared/NetPulseMark.swift`
- **Generator script:** `scripts/generate_icons.py` (Pillow) — regenerate all
  PNGs with `python3 scripts/generate_icons.py`
- **Exports in this folder:** `netpulse-mark-{16,20,32,64,128,256,512,1024}.png`

The app icon (`NetPulse/Resources/Assets.xcassets/AppIcon.appiconset`) uses
the same mark in white, centered on a rounded-square gradient from
`netPulsePrimary` to `netPulseSecondary`.

## Usage rules

- Do not recolor the mark outside the brand palette in `Brand/Colors/Palette.md`.
- Maintain clear space around the mark equal to at least one stroke-width.
- Do not stretch or skew — the mark is designed on a square canvas.
