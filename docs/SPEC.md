# Clocktower Spec

Notifications at clock-aligned intervals, e.g. every 15 min → 1:00, 1:15, 1:30.

## Product

| Surface | Behavior |
| --- | --- |
| iOS app | Short description of the app at the top · master ON/OFF · interval buttons **5 / 10 / 15 / 20 / 30 / 60 min** (single select) · message **"1:20 PM"** or **"The time is 1:20 PM"** · clock **12-hour / 24-hour** · **Time Sensitive** toggle |
| watchOS app | Same controls as iOS |
| iOS widget | Bell icon and text reflect ON/OFF (display only); tap opens the app |
| watchOS complication | Bell icon reflects ON/OFF (`bell.fill` / `bell.slash`); tap opens the watch app |

- Chimes land on clock boundaries (20 min → :00, :20, :40), not relative to when enabled.
- Defaults: **ON, 20 min, "1:20 PM", 12-hour, Time Sensitive off**.
- Notification permission is requested on first launch. If denied, the app shows a banner linking to Settings.
- When notifications are allowed, a **Tips** section at the bottom of the iOS settings says so and shows whether Siri announces chimes (Announce Notifications), with a link to Settings when it doesn't.
- Default notification sound. Interruption level is standard, or Time Sensitive (comes through a Focus) when that toggle is on.

## Data model

```swift
enum ChimeInterval: Int, Codable, CaseIterable { case m5 = 5, m10 = 10, m15 = 15, m20 = 20, m30 = 30, m60 = 60 }
enum MessageStyle: String, Codable, CaseIterable { case timeOnly, sentence }   // "1:20 PM" / "The time is 1:20 PM"
enum ClockFormat: String, Codable, CaseIterable { case twelveHour, twentyFourHour } // "1:20 PM" / "13:20"

struct ChimeSettings: Codable, Equatable {
    var isEnabled = true
    var interval: ChimeInterval = .m20
    var style: MessageStyle = .timeOnly
    var clock: ClockFormat = .twelveHour
    var isTimeSensitive = false
}
```

- Stored as one JSON blob in App Group `UserDefaults` (`group.com.joshclyde.clocktower`), shared by app + widget on each device.
- `Shared/` holds the model, store, formatter, and widget, compiled into all targets.
- 12-hour times include AM/PM ("1:20 PM"); 24-hour times don't ("13:20").

## Notification scheduling

iOS keeps at most **64 pending notifications** per app (a repeating request counts as 1), and content is fixed per request. A repeating "every :15" request can't say "1:15" one hour and "2:15" the next, so each time of day needs its own request: 288 (5 min), 144 (10), 96 (15), 72 (20), 48 (30), 24 (60).

```
reschedule(settings):
  remove all pending chimes
  if !isEnabled: return
  slots = times of day where minute % interval == 0       // 288 / 144 / 96 / 72 / 48 / 24
  if slots.count <= 64:                                    // 30, 60 min
      one request per slot, repeats daily (hour + minute)  → never runs out
  else:                                                    // 5, 10, 15, 20 min
      next 64 slots from now, one-shot                     → ~5 / ~11 / ~16 / ~21 h of coverage
      last one also says "Open Clocktower to keep chimes going"
```

- Content: body = message (e.g. "1:20"); iOS hides notifications with an empty body. The last one-shot chime uses title = message, body = "Open Clocktower to keep chimes going".
- IDs: `chime-HHmm` in both modes (no time of day repeats within 64 one-shots). A new delivery replaces the uncleared one from the day before in Notification Center instead of piling up (to confirm on device).
- Refill (5–20 min): on app launch/foreground, any settings change, background app refresh (best-effort), watch message.

## Sync

```
iPhone = source of truth and the only scheduler
  ├─ iOS widget: App Group defaults + WidgetCenter.reloadAllTimelines()
  └─ watch:      WatchConnectivity
                   phone → watch: updateApplicationContext(settings)
                   watch → phone: sendMessage / transferUserInfo(change) → phone saves, reschedules, pushes context back
                 watch saves context to its App Group → reloads complication
Watch notifications = iPhone notifications mirrored to the watch (no watch scheduling, no duplicates)
```
