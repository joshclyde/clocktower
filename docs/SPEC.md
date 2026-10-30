# Clocktower Spec

Notifications at clock-aligned intervals, e.g. every 15 min → 1:00, 1:15, 1:30.

## Product

| Surface | Behavior |
| --- | --- |
| iOS app | Top to bottom: a **Chimes** section with an **Off / On / Schedule** choice (three buttons, filled red / green / blue when selected) and **Today** (see below), with a description under it: the interval and 3 example times in the chosen clock format (e.g. "Get notifications every 5 minutes, all day." / "Example: 1:00 PM, 1:05 PM, 1:10 PM"; "… during your schedules." for Schedule), "No chimes scheduled. Choose On or turn on a schedule.", or "Chimes are off." · interval buttons **5 / 10 / 15 / 20 / 30 / 60 min** (single select) · **Message**: an example of the message, clock **12-hour / 24-hour**, then text before and after the time (see below) · **Time Sensitive** toggle · **Schedules** (see below) · Tips |
| watchOS app | Same controls as iOS, except schedules: each schedule's toggle, but adding and editing schedules is on the iPhone. The message is shown but edited on the iPhone. No Tips |
| iOS widget | Bell icon and text show Off vs. on (On or Schedule) (display only); tap opens the app |
| watchOS complication | Bell icon shows Off vs. on (`bell.slash` / `bell.fill`); tap opens the watch app |

- **Today**: rows under Off / On / Schedule for the active schedules on today's weekday, by start time ("9:00 AM – 5:00 PM" / "Today"), shown only while set to Schedule. A window that hasn't passed has a toggle that turns that schedule off for the rest of today; once it has passed it shows **Done** (or **Skipped**, if turned off) and no toggle. The footer adds that turning one off lasts until midnight. Refreshes every minute.
- **Schedules** has one row per schedule ("9:00 AM – 5:00 PM" / "Weekdays") with its own toggle, and **Add Schedule**. Tapping a row opens the editor: start time, end time, and day buttons S M T W T F S (all selected for a new schedule). Either time can be set freely. An end at or before the start turns the End label red with "End time must be after the start time." under it, and no days shows "Select at least one day."; Save (Add) stays disabled until both are fixed. Delete from the editor or by swiping the row.
- **Message**: every chime is the user's optional text before the time, the time, and optional text after it ("Stand up 1:20 PM and stretch"); with neither, just the time ("1:20 PM"). The section starts with a gray row showing the whole message for 1:20 PM ("Example: Stand up 1:20 PM and stretch", updating while typing), then the clock choice, then the fields "Text before the time" and "Text after the time". Both fields are optional; while one is being edited and has text, an ⓧ on its right clears it. "Text after the time" doesn't capitalize its first letter, since it continues the sentence. The keyboard's Return key reads **done** in both fields and closes the keyboard, as does starting to scroll the page. The text is saved when editing ends that way (or the app is left), not on every keystroke. The finished message has exactly one space between each part and the time, however many (or few) spaces were typed.
- Chimes land on clock boundaries (20 min → :00, :20, :40), not relative to when enabled.
- Defaults: **On, 20 min, empty before and after text ("1:20 PM"), 12-hour, Time Sensitive off, no schedules**.
- Notification permission is requested on first launch. If denied, the app shows a banner linking to Settings.
- Opening the iOS app (launch or foreground) clears delivered chimes from Notification Center, on the iPhone and (mirrored) the watch (watch to confirm on device).
- When notifications are allowed, a **Tips** section at the bottom of the iOS settings says so and shows whether Siri announces chimes (Announce Notifications), with a link to Settings when it doesn't.
- Default notification sound. Interruption level is standard, or Time Sensitive (comes through a Focus) when that toggle is on.

## Data model

```swift
enum ChimeInterval: Int, Codable, CaseIterable { case m5 = 5, m10 = 10, m15 = 15, m20 = 20, m30 = 30, m60 = 60 }
enum ClockFormat: String, Codable, CaseIterable { case twelveHour, twentyFourHour } // "1:20 PM" / "13:20"
enum Weekday: Int, Codable, CaseIterable { case sunday = 1, monday, …, saturday } // Calendar weekday numbers

struct CustomMessage: Codable, Equatable { var prefix = ""; var suffix = "" }  // either can be empty

struct TimeOfDay: Codable, Hashable, Comparable { var hour: Int; var minute: Int }

struct ChimeSchedule: Codable, Equatable, Identifiable {
    var id = UUID()
    var isEnabled = true                     // the schedule's own toggle
    var start = TimeOfDay(hour: 9)
    var end = TimeOfDay(hour: 17)            // inclusive; after start
    var weekdays = Set(Weekday.allCases)     // at least one
    var skippedUntil: Date?                  // turned off for today → the next midnight
}

enum ChimeMode { case off, on, schedule }  // the UI's Off / On / Schedule; ChimeSettings.mode maps it onto isEnabled + isInfinite

struct ChimeSettings: Codable, Equatable {
    var isEnabled = true          // false = Off
    var isInfinite = true         // while enabled: true = On (every slot, every day), false = Schedule
    var interval: ChimeInterval = .m20
    var customMessage = CustomMessage()
    var clock: ClockFormat = .twelveHour
    var isTimeSensitive = false
    var schedules: [ChimeSchedule] = []
}
```

- Settings saved with the old `style` field ("1:20 PM" / "The time is 1:20 PM") ignore it and load with an empty message.
- Stored as one JSON blob in App Group `UserDefaults` (`group.com.joshclyde.clocktower`), shared by app + widget on each device. Fields missing from older saves take their defaults, so existing users stay On and chime as before.
- `Shared/` holds the model, store, formatter, and widget, compiled into all targets.
- 12-hour times include AM/PM ("1:20 PM"); 24-hour times don't ("13:20").

## Which chimes fire

```
chimes(at date):
  if !isEnabled:  false                              // Off: nothing, whatever else is set
  if isInfinite:  true                               // On: every slot, every day; schedules ignored
  any schedule where
      schedule.isEnabled                             // "active" schedules
      && date's weekday in schedule.weekdays
      && start <= time <= end                        // a chime at the end time fires
      && !(date < schedule.skippedUntil)             // not turned off for today
```

- Slots are still clock-aligned (20 min → :00, :20, :40). A window that starts off a boundary chimes from the next one (9:10 → 9:20).
- `end` is always after `start`, and a schedule has at least one day; the editor won't save otherwise. Schedules saved before the end time was required load with 11:59 PM (they ran until midnight), and ones with no days load with every day.
- Overlapping schedules chime once per slot. Turning one off for today leaves the slots the other covers.
- Turning a schedule off for today sets `skippedUntil` to the next midnight, so it turns itself back on; turning it back on clears it.
- Schedule with no active schedules means no chimes. The Chimes description says so: "No chimes scheduled. Choose On or turn on a schedule."

## Notification scheduling

iOS keeps at most **64 pending notifications** per app (a repeating request counts as 1), and content is fixed per request. A repeating "every :15" request can't say "1:15" one hour and "2:15" the next, so each time of day needs its own request: 288 (5 min), 144 (10), 96 (15), 72 (20), 48 (30), 24 (60).

```
reschedule(settings):
  remove all pending chimes
  if !isEnabled: return
  slots = times of day where minute % interval == 0       // 288 / 144 / 96 / 72 / 48 / 24
  repeating = for each slot:
      chimes every weekday  → one daily request (hour + minute)
      chimes on some days   → one weekly request per day (weekday + hour + minute)
  if repeating.count <= 64 and no schedule turned off for today would still chime before midnight:
      schedule repeating                                   → never runs out
  else:
      next 64 slots from now that fire, one-shot (looking up to 14 days ahead)
      last one also says "Open Clocktower to keep chimes going"
```

| Settings | Requests |
| --- | --- |
| On, 30 / 60 min | 48 / 24 daily repeating |
| On, 5 / 10 / 15 / 20 min | 64 one-shots → ~5 / ~11 / ~16 / ~21 h of coverage |
| Mon–Fri 9 AM–5 PM + Sat–Sun 10 AM–11:59 PM, 30 min | 51 repeating: 15 daily (10 AM–5 PM), 10 weekly (9:00, 9:30 on weekdays), 26 weekly (5:30–11:30 PM on weekends) |
| Same, 20 min, at Thu 2:10 PM | 64 one-shots: Thu 2:20 PM … Sat 7:40 PM |
| Same, 30 min, Mon–Fri turned off for today at Thu 2:10 PM | 64 one-shots from Fri 9:00 AM … Sun 7:00 PM; back to 51 repeating at the first refresh after midnight |
| Same, turned off for today at Thu 6:00 PM | 51 repeating: today's window has passed, so nothing changes |
| Schedule, no active schedules | none |

- A repeating request can't skip one day, so a schedule turned off for today switches to one-shots until midnight.
- Content: body = message (e.g. "1:20"); iOS hides notifications with an empty body. The last one-shot chime uses title = message, body = "Open Clocktower to keep chimes going".
- IDs: `chime-HHmm` per time of day, so a new delivery replaces the uncleared one from the day before in Notification Center instead of piling up (to confirm on device). Weekly requests add the weekday (`chime-0900-2` = Mondays 9:00), so they replace last week's. A one-shot time of day that comes up again within the 64 adds the date (`chime-1420-20260116`).
- Refill (one-shots): on app launch/foreground, any settings change, background app refresh (best-effort), watch message.

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

- A change from the watch carries the watch's whole copy of the settings, which may be out of date (e.g. queued while the iPhone was out of reach). The iPhone keeps its own value for fields the watch can't edit (`customMessage`), so an old copy never replaces them.
