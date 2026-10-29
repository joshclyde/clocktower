# Backlog

Ideas for later. Not committed to; move an item into [SPEC.md](SPEC.md) when it's picked up.

## Spoken chime sound

Play a voice saying the time ("It's three fifteen") as the notification sound, so chimes are heard without reading the screen. Unlike Siri's Announce Notifications, it works without AirPods and needs no setup.

- Bundle one audio clip per chime time (`.caf`/`.aiff`/`.wav`, ≤ 30 s) and set `content.sound = UNNotificationSound(named:)` in `ChimeScheduler`. Every minute an interval can land on (:00, :15, :20, :30, :40, :45) × 24 h = 144 clips per voice and clock format.
- Clips must be pre-recorded or pre-generated: the app isn't running when a local notification fires, so it can't synthesize speech then (`AVSpeechSynthesizer`), and a Notification Service Extension only runs for remote pushes.
- Probably a setting (chime sound: default / spoken), off by default.
- Open questions: app size, which voice, 12- vs 24-hour wording, behavior with the silent switch on.

## Shortcuts actions for every setting

Expose each setting as an action in the Shortcuts app, so chimes can be changed from a shortcut, a Focus or time-of-day automation, Siri, or the Action button (e.g. turn chimes off at bedtime, switch to 15 min during work hours).

- One App Intent per setting, or a single "Set Chime Setting" intent with a parameter per field: chimes on/off, interval, message style, clock format, Time Sensitive. Enums become `AppEnum`s (`ChimeInterval`, `MessageStyle`, `ClockFormat`).
- Probably also a "Get Chime Settings" intent so shortcuts can branch on the current values.
- Each intent applies the change the same way `ChimeController.update` does: save to `SettingsStore`, reschedule via `ChimeScheduler`, and push to the watch with `PhoneSync`. It may run without the app in the foreground, so that path can't depend on SwiftUI state. Reload widget timelines after.
- Register `AppShortcutsProvider` phrases so the common ones ("Turn off Clocktower chimes") work in Siri and Spotlight without the user building a shortcut.
- Open questions: whether the watch app gets its own intents, and how to reach the watch when the change happens while the iPhone app isn't running.

## Widget and complication for schedules

Once the schedule settings are settled in the app, decide what the iOS widget and watch complication show. Today they only reflect the master toggle (`bell.fill` / `bell.slash`, "Chimes On" / "Chimes Off").

- States to tell apart: master off; on with Infinite; on with schedules only (inside a window, between windows, nothing left today); today's schedule turned off.
- Probably show the next chime time or the next window's start when not chiming now, which needs timeline entries at window boundaries and at midnight (when today's schedule toggle resets).
- Open questions: how much fits in the small widget and the circular complication, and whether tapping should allow turning today's schedule off without opening the app.
