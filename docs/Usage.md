# Using Cadence

## Intervals

Cadence has focus, short-break and long-break modes. Set durations, long-break cadence and a daily goal in Settings → Timer.

Presets:

| Preset | Focus | Short break | Long break |
|---|---|---|---|
| Classic | 25 minutes | 5 minutes | 15 minutes |
| Deep work | 50 minutes | 10 minutes | 20 minutes |
| Gentle start | 15 minutes | 3 minutes | 10 minutes |

Duration changes apply to the next interval. Reset to apply them immediately. Presets are available while paused. Resetting or changing mode discards current interval progress; skipping never counts as completed focus.

By default, breaks start automatically and the next focus interval waits for you. You can change both behaviours independently.

The timer uses deadlines, so sleep and relaunch do not reset a running interval. After an overdue interval, Cadence records at most one completion and starts at most one fresh interval. It does not count unattended cycles as completed work.

Closing the window keeps Cadence running in the menu bar. Use its menu to reopen the window or quit.

## Appearance

Settings → General lets Cadence follow the Mac accent colour (purple when the Mac uses Multicolour), or use one of nine colours throughout the app, including breaks. Choose System, Light or Dark independently of the accent.

Tahoe uses native Liquid Glass; Sequoia uses translucent materials. Cadence respects reduced-motion and reduced-transparency accessibility settings. App icon appearances follow the system's icon appearance settings, rather than the app's accent choice.

## Alarms and notifications

Choose from the Apple alert sounds installed on your Mac, set the volume and preview a sound in Settings → Alerts. Alarms repeat until dismissed. System output volume and mute settings still apply. Cadence must be running to play an alarm.

Request access with **Allow notifications…** during onboarding or in Settings → Alerts. macOS shows its permission prompt only when access has not been decided before. If access is off, use **Open System Settings…** to enable Cadence. The status updates when you return to the app, and **Send test notification** checks delivery without changing your timer. The notification toggle is Cadence's preference; it does not override macOS permission.

If macOS cannot request access for a development build, Cadence reports that separately from a denied permission. Install and launch the packaged `Cadence.app` from Applications, rather than running the bare executable. **Copy notification diagnostics** includes the app location, macOS version and observed permission/error for a bug report. Changing the bundle identifier or signing identity can change the application's macOS permission identity. In-app sounds do not require notification permission.

When notification permission is available, Cadence schedules a local banner for the interval deadline. Focus modes may silence it. Notifications do not play a second copy of the app's alarm sound. A scheduled banner may arrive while Cadence is quit; reopening reconciles the elapsed interval.

## Mac integration

The Music button plays or pauses **Apple Music** and opens it if it is not running. It asks for macOS Automation permission. If needed, review access in System Settings → Privacy & Security → Automation. Spotify integration is not included yet.

Keep-awake prevents idle system sleep during a running focus interval. It does not override lid closure or manual sleep.

Launch-at-login works after installing the packaged app in a stable location, such as Applications.

## History and privacy

Daily goals, the seven-day overview and session history count completed focus intervals. Export history to CSV from Insights or Settings → Data. **Reset history…** lets you clear today, the last seven calendar days (including today), an inclusive date range, or all history. Dates use your Mac's time zone. Cadence previews the number of affected intervals and asks for confirmation. This leaves your current timer, round count and settings alone; clearing today's history also clears its daily progress.

**Reset entire app…** stops the timer and alarm, clears intentions and all history, restores default settings, turns off launch at login, cancels Cadence's pending notifications and removes its delivered reminders. Onboarding appears again. Export a CSV first if you want a history backup; resets cannot be undone. A reset cannot revoke macOS notification or Automation permission—use System Settings for those.

Preferences and history live locally in the UserDefaults domain `me.xdan.Cadence`. Upgrading from the previous `uk.xdan.Cadence` identifier copies existing settings, timer state and sessions when the new domain has no corresponding value. Existing data in the new domain takes precedence.

Cadence has no account, telemetry or server.

## Onboarding

Setup appears once on the first launch of this version, including for existing installations. Existing history and settings are preserved. Choose intervals, flow, accent, appearance, daily goal and alarm sound, then optionally request notification access. **Skip setup** keeps your existing settings.

Reopen setup with **Settings → Data → Show onboarding again**. **Cancel** discards unsaved setup choices; finishing applies them without clearing history or interrupting a running or partially completed interval. Resetting the entire app brings back first-run setup. You can always adjust these settings later.
