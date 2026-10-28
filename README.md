# clocktower

Clocktower is a chiming clock for your iPhone and Apple Watch. Pick an interval (every 5, 10, 15, 20, 30 or 60 minutes) and it sends a notification with the current time ("1:20 PM") on the clock boundaries: :00, :20, :40, and so on. Turn chimes on or off from the iOS or watchOS app. A home screen widget and a watch complication show whether chimes are on.

| Target | Platform | Folder |
| --- | --- | --- |
| Clocktower | iOS app | `Clocktower/` |
| ClocktowerWidget | iOS widget | `ClocktowerWidget/` |
| ClocktowerWatch | watchOS app | `ClocktowerWatch/` |
| ClocktowerWatchWidget | watchOS complication | `ClocktowerWatchWidget/` |
| ClocktowerTests | iOS unit tests | `ClocktowerTests/` |

Widget code shared by both widget targets lives in `Shared/`. The Xcode project is generated from `project.yml` — see [DEV_WORKFLOW.md](DEV_WORKFLOW.md).

Product spec: [docs/SPEC.md](docs/SPEC.md). Ideas for later: [docs/BACKLOG.md](docs/BACKLOG.md).
