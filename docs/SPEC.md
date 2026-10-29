# Clocktower Spec

Notifications at clock-aligned intervals, e.g. every 15 min → 1:00, 1:15, 1:30.

## Product

| Surface | Behavior |
| --- | --- |
| iOS app | Top to bottom: master **Chimes** ON/OFF, with a description under it: the interval and 3 example times in the chosen clock format (e.g. "Get notifications every 5 minutes." / "Example: 1:00 PM, 1:05 PM, 1:10 PM"; "… during your schedules." when Infinite is off), "No chimes scheduled. Turn on Infinite or a schedule.", or "Chimes are off." · **Infinite** toggle · **Today** (see below) · interval buttons **5 / 10 / 15 / 20 / 30 / 60 min** (single select) · message **"1:20 PM"** or **"The time is 1:20 PM"** · clock **12-hour / 24-hour** · **Time Sensitive** toggle · **Schedules** (see below) · Tips |
| watchOS app | Same controls as iOS, except schedules: each schedule's toggle, but adding and editing schedules is on the iPhone. No Tips |
| iOS widget | Bell icon and text reflect ON/OFF (display only); tap opens the app |
| watchOS complication | Bell icon reflects ON/OFF (`bell.fill` / `bell.slash`); tap opens the watch app |

- **Today** lists the active schedules for today's weekday by start time, hidden when the master toggle is off or there are none. Each window that hasn't passed has a toggle that turns that schedule off for the rest of today. Once a window has passed it shows **Done** (or **Skipped**, if turned off) and no toggle. While Infinite is on, the section is dimmed and disabled with the note "Infinite is on, so schedules aren't used." The section refreshes every minute.
- **Schedules** has one row per schedule ("9:00 AM – 5:00 PM" / "Weekdays") with its own toggle, and **Add Schedule**. Tapping a row opens the editor: start time, end time, and day buttons S M T W T F S (all selected for a new schedule). Delete from the editor or by swiping the row.
- Chimes land on clock boundaries (20 min → :00, :20, :40), not relative to when enabled.
- Defaults: **ON, Infinite on, 20 min, "1:20 PM", 12-hour, Time Sensitive off, no schedules**.
- Notification permission is requested on first launch. If denied, the app shows a banner linking to Settings.
- When notifications are allowed, a **Tips** section at the bottom of the iOS settings says so and shows whether Siri announces chimes (Announce Notifications), with a link to Settings when it doesn't.
- Default notification sound. Interruption level is standard, or Time Sensitive (comes through a Focus) when that toggle is on.

## Data model

```swift
enum ChimeInterval: Int, Codable, CaseIterable { case m5 = 5, m10 = 10, m15 = 15, m20 = 20, m30 = 30, m60 = 60 }
enum MessageStyle: String, Codable, CaseIterable { case timeOnly, sentence }   // "1:20 PM" / "The time is 1:20 PM"
enum ClockFormat: String, Codable, CaseIterable { case twelveHour, twentyFourHour } // "1:20 PM" / "13:20"
enum Weekday: Int, Codable, CaseIterable { case sunday = 1, monday, …, saturday } // Calendar weekday numbers

struct TimeOfDay: Codable, Hashable, Comparable { var hour: Int; var minute: Int }

struct ChimeSchedule: Codable, Equatable, Identifiable {
    var id = UUID()
    var isEnabled = true                     // the schedule's own toggle
    var start = TimeOfDay(hour: 9)
    var end = TimeOfDay(hour: 17)            // inclusive; after start
    var weekdays = Set(Weekday.allCases)     // at least one
    var skippedUntil: Date?                  // turned off for today → the next midnight
}

struct ChimeSettings: Codable, Equatable {
    var isEnabled = true          // master toggle
    var isInfinite = true         // chime all day, every day; off → follow the schedules
    var interval: ChimeInterval = .m20
    var style: MessageStyle = .timeOnly
    var clock: ClockFormat = .twelveHour
    var isTimeSensitive = false
    var schedules: [ChimeSchedule] = []
}
```

- Stored as one JSON blob in App Group `UserDefaults` (`group.com.joshclyde.clocktower`), shared by app + widget on each device. Fields missing from older saves take their defaults, so existing users keep Infinite on and chime as before.
- `Shared/` holds the model, store, formatter, and widget, compiled into all targets.
- 12-hour times include AM/PM ("1:20 PM"); 24-hour times don't ("13:20").

## Which chimes fire

```
chimes(at date):
  if !isEnabled:  false                              // master off: nothing, whatever else is set
  if isInfinite:  true                               // every slot, every day; schedules ignored
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
- Infinite off with no active schedules means no chimes. The master toggle's description says so: "No chimes scheduled. Turn on Infinite or a schedule."

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
| Infinite, 30 / 60 min | 48 / 24 daily repeating |
| Infinite, 5 / 10 / 15 / 20 min | 64 one-shots → ~5 / ~11 / ~16 / ~21 h of coverage |
| Mon–Fri 9 AM–5 PM + Sat–Sun 10 AM–11:59 PM, 30 min | 51 repeating: 15 daily (10 AM–5 PM), 10 weekly (9:00, 9:30 on weekdays), 26 weekly (5:30–11:30 PM on weekends) |
| Same, 20 min, at Thu 2:10 PM | 64 one-shots: Thu 2:20 PM … Sat 7:40 PM |
| Same, 30 min, Mon–Fri turned off for today at Thu 2:10 PM | 64 one-shots from Fri 9:00 AM … Sun 7:00 PM; back to 51 repeating at the first refresh after midnight |
| Same, turned off for today at Thu 6:00 PM | 51 repeating: today's window has passed, so nothing changes |
| Infinite off, no active schedules | none |

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
