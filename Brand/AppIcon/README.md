# NetPulse App Icon

Generated at every required macOS size (16 – 512pt, @1x and @2x) via
`scripts/generate_icons.py` into
`NetPulse/Resources/Assets.xcassets/AppIcon.appiconset/`.

Composition: rounded-square gradient (`netPulsePrimary` → `netPulseSecondary`)
with the NetPulse pulse-mark centered in white at ~68% of the canvas, leaving
native macOS icon padding around the edges.

To regenerate after any palette change:

```bash
python3 scripts/generate_icons.py
```
