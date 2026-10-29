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

## View scheduled chimes

Let the user see every notification Clocktower has asked iOS to deliver, and why it's set up that way, so it's clear when chimes will keep going and when they'll stop without the app.

- One row below the Tips section in `SettingsView` (e.g. "Scheduled chimes", with the count), using a `NavigationLink` to a full list.
- The list reads the real pending requests from `UNUserNotificationCenter.pendingNotificationRequests()` rather than recomputing them with `ChimePlanner`, so it shows what iOS will actually deliver. Each row shows the time and the message; the last one-shot shows its "reopen the app" reminder.
- A header explains which case applies (see [SPEC.md](SPEC.md) → Notification scheduling):
  - **Within the 64 limit** (30, 60 min): one daily-repeating notification per time, so chimes never run out.
  - **Over the 64 limit** (5, 10, 15, 20 min): only the next 64 are scheduled, ending at a given time. Chimes stop then unless the app is opened (or background refresh tops them up), and the last one reminds the user to open it.
- Empty state when chimes are off or notifications aren't allowed.
- Open questions: whether the watch app gets the same view for its own pending notifications, and whether to group the list by day.

## Cleaner history for stacked PRs

Change the stacked-PR workflow in [CLAUDE.md](../CLAUDE.md) so the history isn't full of merge commits. Today each layer merges into `feature/<name>` with a merge commit, review fixes get merged up through every layer above, and `main` gets merged into `feature/<name>`, so a single feature can add a pile of "Merge pull request…" and "Merge branch…" commits.

- Options:
  - **Squash the project PR** (`feature/<name>` → `main`): the feature lands on `main` as one commit, whatever happened on the feature branch. Simplest; loses the per-layer commits on `main`.
  - **Squash or rebase-merge each layer**, then rebase the layers above onto `feature/<name>` (`git rebase --onto`, or `git rebase --update-refs` to move the whole stack at once) and force-push them. Without the rebase, GitHub shows the lower layer's changes again in the next PR's diff, because its original commits are no longer ancestors.
  - **Rebase instead of merge** for review fixes and for bringing in `main`, again with force-pushes on the stack branches.
- Whatever's chosen, update steps 6–9 of the CLAUDE.md workflow and the repo's allowed merge methods in GitHub settings to match.
- Open questions: whether per-layer commits are worth keeping on `main`, and whether force-pushing stack branches with open PRs is acceptable (it rewrites what the user may have already reviewed).

## Stop the settings page from jumping

Review `SettingsView` for settings whose change adds or removes UI above the control the user just touched, which shifts the page under their finger. For example, toggling a schedule setting near the bottom of the page can add or remove rows higher up, so the page jumps.

- Go through every control and note what each change shows, hides, or resizes, and where that is relative to the control.
- Possible fixes: keep conditional UI below the control that drives it; keep rows in place and disable or dim them instead of removing them; or keep the touched control on screen with `ScrollViewReader` / `scrollPosition`. Animating the change (`withAnimation`) makes it smoother but doesn't stop the jump on its own.
- Check the watch app's settings too.

## Lock the iPhone app to portrait

Stop the iOS app from rotating on iPhone; it should stay in portrait. The settings page is a single scrolling list that doesn't gain anything in landscape.

- Set the supported orientations for the `Clocktower` target in `project.yml` (the Info.plist is generated): `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait`. Today no orientation keys are set, so it falls back to Xcode's default (portrait plus both landscapes).
- Decide whether to also allow upside-down portrait (most iPhone apps don't).
- Open questions: whether the app runs on iPad at all (no `TARGETED_DEVICE_FAMILY` is set), and if so whether iPad stays free to rotate, since iPad apps that support multitasking must support every orientation.
