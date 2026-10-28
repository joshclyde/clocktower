# Clocktower Spec

Notifications at clock-aligned intervals, e.g. every 15 min → 1:00, 1:15, 1:30.

## Product

| Surface | Behavior |
| --- | --- |
| iOS app | Master ON/OFF · interval buttons **15 / 20 / 30 / 60 min** (single select) · message **"1:20 PM"** or **"The time is 1:20 PM"** · clock **12-hour / 24-hour** |
| watchOS app | Same controls as iOS |
| iOS widget | Shows ON/OFF; tapping toggles it (interactive widget) |
| watchOS complication | Bell icon reflects ON/OFF (`bell.fill` / `bell.slash`); tap opens the watch app |

- Chimes land on clock boundaries (20 min → :00, :20, :40), not relative to when enabled.
- Defaults: **ON, 20 min, "1:20 PM", 12-hour**.
- Notification permission is requested on first launch. If denied, the app shows a banner linking to Settings.
- Default notification sound, standard interruption level (not Time Sensitive).

## Data model

```swift
enum ChimeInterval: Int, Codable, CaseIterable { case m15 = 15, m20 = 20, m30 = 30, m60 = 60 }
enum MessageStyle: String, Codable, CaseIterable { case timeOnly, sentence }   // "1:20 PM" / "The time is 1:20 PM"
enum ClockFormat: String, Codable, CaseIterable { case twelveHour, twentyFourHour } // "1:20 PM" / "13:20"

struct ChimeSettings: Codable, Equatable {
    var isEnabled = true
    var interval: ChimeInterval = .m20
    var style: MessageStyle = .timeOnly
    var clock: ClockFormat = .twelveHour
}
```

- Stored as one JSON blob in App Group `UserDefaults` (`group.com.joshclyde.clocktower`), shared by app + widget on each device.
- `Shared/` holds the model, store, formatter, and toggle intent, compiled into all targets.
- 12-hour times include AM/PM ("1:20 PM"); 24-hour times don't ("13:20").

## Notification scheduling

iOS keeps at most **64 pending notifications** per app (a repeating request counts as 1), and content is fixed per request. A repeating "every :15" request can't say "1:15" one hour and "2:15" the next, so each time of day needs its own request: 96 (15 min), 72 (20), 48 (30), 24 (60).

```
reschedule(settings):
  remove all pending chimes
  if !isEnabled: return
  slots = times of day where minute % interval == 0       // 96 / 72 / 48 / 24
  if slots.count <= 64:                                    // 30, 60 min
      one request per slot, repeats daily (hour + minute)  → never runs out
  else:                                                    // 15, 20 min
      next 64 slots from now, one-shot                     → ~16 h / ~21 h of coverage
      last one also says "Open Clocktower to keep chimes going"
```

- Content: body = message (e.g. "1:20"); iOS hides notifications with an empty body. The last one-shot chime uses title = message, body = "Open Clocktower to keep chimes going".
- IDs: `chime-HHmm` (repeating) or `chime-<epoch>` (one-shot), so a reschedule replaces everything.
- Refill (15/20 min): on app launch/foreground, any settings change, background app refresh (best-effort), watch message, widget toggle.

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

## Risks to verify early

- **Widget toggle process:** the toggle intent may run in the widget extension. If it can't reschedule or reach the watch from there, the iPhone app reconciles on its next launch or background refresh.
