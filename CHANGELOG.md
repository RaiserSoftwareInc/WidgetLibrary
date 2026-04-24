# Changelog

All notable changes documented here. Format loosely follows Keep a Changelog.

## 0.6.1 — 2026-04-24

### Fixed
- **Restored backward compatibility for `CatalogApp.entries`.** 0.6.0 silently
  flipped `entries` from `List<CatalogEntry>` to `List<CatalogEntry> Function()`,
  breaking every downstream call site on a minor version bump. 0.6.1 accepts
  both shapes: `entries:` (legacy list, `@Deprecated`) and `entriesBuilder:`
  (new function, recommended). Exactly one is required. Removal of the
  deprecated `entries` field is scheduled for 1.0.0.

### Notes
- If you pinned to `v0.6.0` and changed your call sites to pass a function
  reference, rename `entries:` to `entriesBuilder:` to stay on the
  non-deprecated path.
- If you were on `v0.5.1` with `entries: buildCatalog()`, nothing is forced
  on you — your existing call site compiles and runs. Upgrade to
  `entriesBuilder: buildCatalog` whenever you want hot-reload pickup of
  edited entry defaults without a full restart.

## 0.6.0 — 2026-04-24 — **AVOID**

### Added
- `CatalogEntry.live({knobs, builder})` with typed knob controls
  (`DoubleKnob`, `IntKnob`, `BoolKnob`, `StringKnob`, `EnumKnob<T>`,
  `ColorKnob`). Detail screen renders an inline split: preview on top,
  knob panel below. Dragging a knob rebuilds the preview live.
- `KnobValues` typed accessor exported from `widget_library.dart`.
- Hot-reload reconcile: editing a `defaultValue` surfaces the new default
  for knobs the user has not touched, preserves user-dragged values on
  matching ids, drops removed ids, seeds new ids.
- Marionette-ready keys: `wl.detail.knob_panel`, `wl.detail.knob.<id>`,
  `wl.detail.knob.<id>.control`, `wl.detail.knob.<id>.value`,
  `wl.detail.knob.<id>.reset`, `wl.detail.knobs.reset_all`.

### Changed — BREAKING
- `CatalogApp.entries` type changed from `List<CatalogEntry>` to
  `List<CatalogEntry> Function()`. This was not documented, not migration-
  noted, and shipped on a minor version bump. **Use 0.6.1 instead.**

## 0.5.1

Prior feature work. No changelog kept before 0.6.1.
