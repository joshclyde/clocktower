# Conventions

Rules to follow when changing the code, beyond what `docs/SPEC.md` describes. `CLAUDE.md` points here.

## Saved data

`ChimeSettings` and every type inside it (`CustomMessage`, `ChimeSchedule`, `TimeOfDay`, and the enums) are saved as one JSON blob in App Group `UserDefaults` on each device, and sent between the iPhone and the watch (see `docs/SPEC.md` → Data model, Sync). After an update, the new build loads settings saved by the old one, and the iPhone and watch can briefly run different builds while the watch app updates.

If any part of that JSON fails to decode, `SettingsStore.load()` falls back to `ChimeSettings()` and the sync payload is dropped. One field that can't be read resets **every** setting, so:

- **Decode field by field.** Every saved struct has an `init(from:)` in an extension that reads each field with `decodeIfPresent(…) ?? <default>`. Swift's synthesized decoder ignores property defaults and throws when any key is missing. Putting the init in an extension keeps the memberwise initializer. See `ChimeSettings`, `ChimeSchedule` and `CustomMessage`. The one exception is `TimeOfDay`, whose `hour` and `minute` have always both been saved and have no sensible default; give it the same init before adding a field to it.
- **New saved type:** give it the field-by-field `init(from:)` from the start, even though every key exists today. The first field added later would otherwise break every earlier save.
- **Adding a field:**
  - Give it a default that keeps existing users' behavior: they should chime exactly as before.
  - Add its `decodeIfPresent` line. The encoder is synthesized and needs no change.
  - Add a test that decodes JSON saved before the field existed, like `decodesSettingsSavedBeforeSchedules`.
- **Never rename a field or change its type.** The property name is the JSON key. Keep the old name and explain it in a comment, as `isInfinite` does. If a rename can't be avoided, keep the old key with `CodingKeys` (`case newName = "oldName"`).
- **Enum cases are saved by raw value.** Never change or reuse a raw value. A save that holds a removed case fails to decode, so keep old cases, or decode that field with `(try? container.decodeIfPresent(…)) ?? <default>`.
- **Removing a field:** delete it; the leftover key in old saves is ignored. If users' old choice should carry over, convert it in `init(from:)`. Either way, say in `docs/SPEC.md` what happens to it, as for the old `style`.
- **Fields the watch can't edit:** the watch sends back its whole copy of the settings, which may be out of date, and the iPhone applies it. Keep the iPhone's value for such fields in `ChimeController.receive`, as `customMessage` does.
- **Docs:** update the data model in `docs/SPEC.md`.
