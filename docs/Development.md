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

The script builds arm64 and x86_64 release executables, combines them into a universal binary, compiles assets, merges the generated icon metadata, creates the bundle, applies a signature (ad-hoc by default), and packages `dist/Cadence-macOS.zip`.

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
2. `macos-15` runs tests, builds both architectures, downloads the compiled assets, validates the bundle and signature, launches the packaged app, probes the native notification request without answering the OS prompt, and uploads the app ZIP, a screenshot and transparent timer layers.

No signing secrets are required for development builds. To use an installed stable signing certificate locally, supply `CADENCE_SIGNING_IDENTITY` to `scripts/build.sh`. Distribution builds will need Developer ID signing and notarisation. Do not add APNs or critical-alert entitlements for Cadence's ordinary local reminders.

Ad-hoc signatures can change across builds. macOS notification permission belongs to the OS application identity, so test permission upgrades using the packaged app in a stable location and a stable signing identity. Correct status handling cannot repair a stale or unsupported OS registration. If requesting access fails before a prompt appears, copy diagnostics from Settings → Alerts and inspect the installed bundle/signature rather than assuming the user declined.

## Project layout

| Path | Purpose |
|---|---|
| `Sources/CadenceCore` | Timer state, persistence, history date ranges and testable notification coordination |
| `Sources/Cadence` | App, dashboard, menu panel, insights, settings and macOS services |
| `Tests/CadenceCoreTests` | Timer behaviour, permission changes/errors, async notification replacement, calendar ranges and reset persistence |
| `Resources/Cadence.icon` | Supplied layered Icon Composer design |
| `Resources/Colors.xcassets` | Cadence's default accent colour |
| `scripts/build.sh` | Universal app packaging |
| `scripts/compile-assets.sh` | Icon and accent compilation |
| `scripts/merge-asset-info.py` | Generated asset metadata integration |
| `scripts/export-icon-layers.swift` | Transparent timer layers for design work |

The older `scripts/icon.swift` is a reference for the previous generated icon; it is not used in packaging. See [Icon Composer notes](IconComposer-notes.md) for design measurements and the asset handoff.

## Current limitations

- The system permission prompt and delivery need hands-on verification on a real Mac; unit tests use an injected notification client and never grant OS permissions.
- Automation permissions, audible alarms, login registration and Tahoe icon appearance changes need hands-on validation beyond CI's launch test.
- Development artifacts are ad-hoc signed, not notarised.

## Permission and reset checks

On Sequoia and Tahoe, install the packaged app in Applications. In first-run setup, choose Allow notifications and confirm the macOS prompt. In Settings → Alerts, the action should become Send test notification with an allowed status. Toggle Cadence's permission off and on in System Settings and return to verify the status refreshes. Check a paused timer cancels its reminder, then start a short interval and verify one banner and the selected in-app alarm. Repeat with Focus enabled to check the explanatory text.

Test onboarding replay with existing history and a partly completed timer. Confirm selected history resets include both custom dates and preserve records outside the range. Export a backup, then reset the entire app and relaunch: no timer/task/history should return, launch at login should be off, defaults should be restored, and onboarding should remain pending until completed or skipped. The legacy bundle's data must not be re-imported after resetting.

The CI artifact **Cadence-notification-probe** records whether the native permission request returns an error or remains awaiting a user decision. It does not assert access was granted. To run the same probe locally (with Cadence closed), use `open dist/Cadence.app --args --notification-probe "$PWD/dist/notification-probe.txt"`. This explicitly requests notification permission and may show the macOS prompt; ordinary launches never run the probe.
