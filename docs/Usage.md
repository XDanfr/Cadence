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

**Known issue:** notification permission handling is currently unreliable. In-app sounds do not require notification permission.

When notification permission is available, Cadence schedules a local banner for the interval deadline. Focus modes may silence it. Notifications do not play a second copy of the app's alarm sound. A scheduled banner may arrive while Cadence is quit; reopening reconciles the elapsed interval.

## Mac integration

The Music button plays or pauses **Apple Music** and opens it if it is not running. It asks for macOS Automation permission. If needed, review access in System Settings → Privacy & Security → Automation. Spotify integration is not included yet.

Keep-awake prevents idle system sleep during a running focus interval. It does not override lid closure or manual sleep.

Launch-at-login works after installing the packaged app in a stable location, such as Applications.

## History and privacy

Daily goals, the seven-day overview and session history count completed focus intervals. Export history to CSV from Insights. Clearing history requires confirmation.

Preferences and history live locally in the UserDefaults domain `me.xdan.Cadence`. Upgrading from the previous `uk.xdan.Cadence` identifier copies existing settings, timer state and sessions when the new domain has no corresponding value. Existing data in the new domain takes precedence.

Cadence has no account, telemetry or server.
