# Changelog

All notable changes documented here. Format loosely follows Keep a Changelog.

## 0.7.3 — 2026-10-03

### Changed
- **Detail screen reuses the grid's entry.** A grid tile passes its cached
  `CatalogEntry` to `DetailScreen`, so opening an entry no longer calls
  `entriesBuilder()` and reconstructs the whole catalog. Hot reload
  (`reassemble`) and a builder change still look the entry up again by name.
- **Grid filters outside `build`.** Lowercase names are computed once when the
  catalog is cached. The filtered list is recomputed only on a search
  keystroke or a category tap, not on every rebuild. A theme toggle no longer
  re-filters.
- **Legacy `entries:` keeps one builder identity.** `CatalogApp` resolves the
  deprecated list into a builder once instead of on every build, so a theme
  toggle no longer resets the grid cache for 0.5.x call sites.

## 0.7.2 — 2026-10-03

### Changed
- **Knob rows rebuild independently.** `KnobPanel` no longer wraps every row
  in one `ListenableBuilder`. Each row sits in a `KnobValueBuilder` that
  rebuilds only when its own knob value changes. The panel itself rebuilds
  only when `reconcile` replaces the knob list. A slider drag now rebuilds one
  row and the preview, not every row.
- **`KnobController.set` skips no-op writes.** Setting a knob to its current
  value no longer calls `notifyListeners`, so the preview does not rebuild.
- **Specs sections are built once per panel build.** The widget-tree walk
  moved out of `_TreeSection.build` into `SpecsPanel.build`, and the section
  list is created outside the `DraggableScrollableSheet` builder.
- **`ColorRow` reads the color scheme once** instead of twice per swatch.

## 0.7.1 — 2026-08-22

### Changed
- **Grid caches the catalog.** `GridScreen` calls `entriesBuilder()` once at
  mount, on hot reload (`reassemble`), and when the builder changes. A search
  keystroke, category tap, or theme toggle no longer reconstructs every
  `CatalogEntry`. Tiles keep a stable entry identity so unchanged tiles skip
  rebuilds.
- **Grid thumbnails freeze animations.** Each tile preview sits inside
  `TickerMode(enabled: false)` and a `RepaintBoundary`. Animated widgets show
  their first frame in the grid; the detail screen still animates. Tile clip
  is `Clip.hardEdge` instead of `Clip.antiAlias`.
- **`KnobController.values` returns a view.** `UnmodifiableMapView` instead of
  a `Map.unmodifiable` copy on every read.

### Fixed
- **Search bar controller leak.** `_SearchBar` created a new
  `TextEditingController` on every build and never disposed it.

## 0.7.0 — 2026-05-22

### Added
- **Marionette keys for the main (grid) page.** `wl.grid_screen` and
  `wl.detail_screen` screen-root markers, `wl.grid.no_matches` for dead-end
  searches, and a visible `wl.grid.result_count` label (e.g. `12 results`,
  singular `1 result`). Lets an AI agent confirm the active screen, detect empty
  searches, and read the match count without enumerating tiles.
- **Example app wires `MarionetteBinding` in debug.** `example/lib/main.dart`
  now calls `MarionetteBinding.ensureInitialized()` under `kDebugMode`, so the
  demo is agent-drivable out of the box. `marionette_flutter ^0.5.0` is an
  example-only dev dependency (the core library gains no new dependency); the
  example's minimum Flutter is now 3.27.0 for Marionette's transitive deps.

## 0.6.2 — 2026-04-24

### Fixed
- **`EnumKnob<T>` runtime TypeError in detail screen.** The knob panel
  dispatched rows via `EnumRow<dynamic>`, which erased `T` and caused
  `labelOf?.call(value)` to fail with
  `type '(MyEnum) => String' is not a subtype of type '((dynamic) => String)?'`
  whenever a caller supplied a typed `labelOf`. Added `EnumKnob<T>.labelFor`,
  a cast helper that runs inside the `T`-reified scope of the knob; the row
  now routes all label lookups through it. `labelOf` field signature
  unchanged — existing call sites keep working.
- **`const EnumKnob(...)` now compiles.** Removed the non-const-evaluable
  `values.length > 0` assert that blocked const construction and forced
  callers into `prefer_const_constructors` lint noise on surrounding knobs.

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
