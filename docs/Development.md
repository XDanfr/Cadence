# Developing Cadence

Cadence is a Swift Package with a SwiftUI/AppKit executable and a portable timer core. There are no third-party package dependencies. The deployment target is **macOS 15.0**; Tahoe APIs are availability-guarded.

## Requirements

- Xcode 26.3 or later, with the macOS 26 SDK.
- A Tahoe host to render the layered Icon Composer assets.

You can open `Package.swift` in Xcode. For notifications, automation permission and login items, run the packaged `.app` rather than the bare Swift Package executable.

## Build on Tahoe

```sh
swift test
bash scripts/build.sh
open dist/Cadence.app
```

The script builds arm64 and x86_64 release executables, combines them into a universal binary, compiles assets, merges the generated icon metadata, creates the bundle, applies an ad-hoc signature, and packages `dist/Cadence-macOS.zip`.

## Build on Sequoia

Apple's layered-icon renderer crashed on the Sequoia Actions runner, so icon compilation runs on Tahoe while app compilation and launch testing remain on Sequoia.

Download **Cadence-compiled-assets** from a successful Actions run and extract it, for example to `dist/compiled-assets`. Then:

```sh
swift test
CADENCE_COMPILED_ASSETS=dist/compiled-assets bash scripts/build.sh
open dist/Cadence.app
```

Use assets from the same source revision as the app when changing the icon or accent assets. The extracted directory must contain `Resources/` and `asset-info.plist`.

## GitHub Actions

The workflow has two jobs:

1. `macos-26` compiles `Resources/Cadence.icon` and `Resources/Colors.xcassets`, targeting macOS 15. The output includes `Assets.car`, a legacy `Cadence.icns` and generated plist metadata.
2. `macos-15` runs tests, builds both architectures, downloads the compiled assets, validates the bundle and signature, launches the packaged app, and uploads the app ZIP, a screenshot and transparent timer layers.

No signing secrets are required for development builds. Distribution builds will need Developer ID signing and notarisation.

## Project layout

| Path | Purpose |
|---|---|
| `Sources/CadenceCore` | Timer state, sessions and preferences |
| `Sources/Cadence` | App, dashboard, menu panel, insights, settings and macOS services |
| `Tests/CadenceCoreTests` | Timing, pause/resume, cadence, skips, persistence and preference migration |
| `Resources/Cadence.icon` | Supplied layered Icon Composer design |
| `Resources/Colors.xcassets` | Cadence's default accent colour |
| `scripts/build.sh` | Universal app packaging |
| `scripts/compile-assets.sh` | Icon and accent compilation |
| `scripts/merge-asset-info.py` | Generated asset metadata integration |
| `scripts/export-icon-layers.swift` | Transparent timer layers for design work |

The older `scripts/icon.swift` is a reference for the previous generated icon; it is not used in packaging. See [Icon Composer notes](IconComposer-notes.md) for design measurements and the asset handoff.

## Current limitations

- Notification permission handling needs investigation on real Macs.
- Automation permissions, audible alarms, login registration and Tahoe icon appearance changes need hands-on validation beyond CI's launch test.
- Development artifacts are ad-hoc signed, not notarised.
