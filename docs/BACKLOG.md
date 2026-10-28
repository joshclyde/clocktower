# Backlog

Ideas for later. Not committed to; move an item into [SPEC.md](SPEC.md) when it's picked up.

## Spoken chime sound

Play a voice saying the time ("It's three fifteen") as the notification sound, so chimes are heard without reading the screen. Unlike Siri's Announce Notifications, it works without AirPods and needs no setup.

- Bundle one audio clip per chime time (`.caf`/`.aiff`/`.wav`, ≤ 30 s) and set `content.sound = UNNotificationSound(named:)` in `ChimeScheduler`. Every minute an interval can land on (:00, :15, :20, :30, :40, :45) × 24 h = 144 clips per voice and clock format.
- Clips must be pre-recorded or pre-generated: the app isn't running when a local notification fires, so it can't synthesize speech then (`AVSpeechSynthesizer`), and a Notification Service Extension only runs for remote pushes.
- Probably a setting (chime sound: default / spoken), off by default.
- Open questions: app size, which voice, 12- vs 24-hour wording, behavior with the silent switch on.
