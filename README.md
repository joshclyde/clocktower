# clocktower

iOS + watchOS app that sends notifications at user-chosen times (on the hour, every 15/30 min, etc.).

| Target | Platform | Folder |
| --- | --- | --- |
| Clocktower | iOS app | `Clocktower/` |
| ClocktowerWidget | iOS widget | `ClocktowerWidget/` |
| ClocktowerWatch | watchOS app | `ClocktowerWatch/` |
| ClocktowerWatchWidget | watchOS complication | `ClocktowerWatchWidget/` |
| ClocktowerTests | iOS unit tests | `ClocktowerTests/` |

Widget code shared by both widget targets lives in `Shared/`. The Xcode project is generated from `project.yml` — see [DEV_WORKFLOW.md](DEV_WORKFLOW.md).

Product spec: [docs/SPEC.md](docs/SPEC.md). Ideas for later: [docs/BACKLOG.md](docs/BACKLOG.md).
