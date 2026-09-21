# NetPulse Typography

Built entirely on the system font (SF Pro), so it always matches macOS and
respects Dynamic Type. Source of truth: `NetPulse/Utilities/Font+Brand.swift`.

| Token | Size / Weight | Used for |
|---|---|---|
| `netPulseAppTitle` | 15pt semibold, rounded | "NetPulse" header in the popup |
| `netPulseSectionTitle` | 11pt semibold, small caps | Section headers ("DOWNLOAD", "DATA USAGE") |
| `netPulseMetricValue` | 22pt bold, rounded, monospaced digits | Primary speed numbers |
| `netPulseMetricValueLarge` | 30pt bold, rounded, monospaced digits | Hero numbers (speed test results) |
| `netPulseMetricLabel` | 11pt medium | "DOWNLOAD" / "UPLOAD" labels |
| `netPulseBody` | 12pt regular | Standard row text |
| `netPulseSecondary` | 11pt regular | De-emphasized row text |
| `netPulseCaption` | 10pt regular | Footnotes, disclosures, empty states |
| `netPulseSettingsLabel` | 12pt medium | Settings form labels |

Numbers always use monospaced digits so the menu bar and metric tiles don't
visually jitter as values change width.
