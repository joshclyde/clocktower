# Dev Workflow

## Setup (once)

```sh
brew install xcodegen
echo 'DEVELOPMENT_TEAM = <YOUR_TEAM_ID>' > Config/Local.xcconfig   # Xcode → Settings → Accounts
xcodegen
open Clocktower.xcodeproj
```

Re-run `xcodegen` after editing `project.yml` or adding/removing files.

## Test

- Xcode: scheme `Clocktower`, ⌘U
- CLI:
  ```sh
  xcodebuild test -project Clocktower.xcodeproj -scheme Clocktower \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Run in Simulator

- iOS: scheme `Clocktower` → iPhone simulator → ⌘R
- watchOS: scheme `ClocktowerWatch` → Apple Watch simulator → ⌘R

## Launch on iPhone

1. Connect iPhone; enable Developer Mode (Settings → Privacy & Security).
2. Scheme `Clocktower` → your iPhone → ⌘R.
3. If prompted, trust the developer (Settings → General → VPN & Device Management).

## Launch on Apple Watch

1. Watch paired to that iPhone; enable Developer Mode on the watch (Settings → Privacy & Security).
2. Scheme `ClocktowerWatch` → your watch → ⌘R.

## Widget & Complication

- iOS widget: long-press Home Screen → Edit → Add Widget → Clocktower.
- Complication: long-press watch face → Edit → Complications → Clocktower.

## App Icon

- Sources: `docs/icon/AppIcon.svg` (default), `AppIcon-Dark.svg`, `AppIcon-Tinted.svg` (grayscale; iOS applies the tint).
- After editing, export each at 1024×1024 PNG **without alpha** into `Clocktower/Assets.xcassets/AppIcon.appiconset/` (same file names). The watch uses a copy of `AppIcon.png` in `ClocktowerWatch/Assets.xcassets/AppIcon.appiconset/`.
