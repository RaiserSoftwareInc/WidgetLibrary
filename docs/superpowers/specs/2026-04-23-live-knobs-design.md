# Live Knobs for Widget Library — Design

Date: 2026-04-23
Status: Approved (brainstorming phase)

## 1. Overview

Add a live-knob system to the `widget_library` package so catalog entries can
declare typed, reactive parameters (sliders, toggles, dropdowns, text, color)
rendered next to the preview. Dragging a knob rebuilds the preview in the same
frame. Entry construction is moved to builder functions so Flutter hot reload
picks up default-value edits without a full restart. The feature is additive:
existing string-keyed `states` entries continue to render unchanged.

## 2. Decisions

- **Where the knob system lives:** inside the `widget_library` package
  (this repo). Option (a) in the task brief. The package is internal
  (`publish_to: none`) and we control the source.
- **Value storage:** a single `ChangeNotifier` owning a
  `Map<String, Object?>` keyed by knob id, wrapped by a typed `KnobValues`
  accessor. Rationale: simplest reconciliation story for hot reload, one
  `ListenableBuilder` around the preview is enough, avoids per-knob notifier
  plumbing and avoids pulling Riverpod into the library.
- **Panel layout:** inline split below the preview
  (`Expanded(preview) / Divider / Expanded(knob panel)`). Always visible when
  an entry declares knobs. Matches the mobile-inspector pattern and keeps
  preview + knobs on-screen simultaneously.
- **Hot-reload-safe registration:** `CatalogApp` takes
  `required List<CatalogEntry> Function() entries`, invoked inside `build()`
  on every frame. This is the only supported API — no dual path. Consumers
  migrate by dropping the trailing `()` on their builder function.

## 3. Public API

### 3.1 Knob hierarchy (`lib/src/knobs/knob.dart`)

```dart
sealed class Knob<T> {
  final String id;
  final String label;
  final T defaultValue;
  const Knob({required this.id, required this.label, required this.defaultValue});
}

class DoubleKnob extends Knob<double> {
  final double min;
  final double max;
  final double? step;
}

class IntKnob extends Knob<int> {
  final int min;
  final int max;
  final int step;
}

class BoolKnob extends Knob<bool> {}

class StringKnob extends Knob<String> {
  final String? hint;
}

class EnumKnob<T> extends Knob<T> {
  final List<T> values;
  final String Function(T)? labelOf;
}

class ColorKnob extends Knob<Color> {
  final List<Color>? swatches;
}
```

Nullable fields (e.g. "auto safe-area vs fixed topInset") are modeled by the
consumer pairing a `BoolKnob` with a value knob in the `builder` body. No
dedicated nullable knob type.

### 3.2 `KnobValues` (`lib/src/knobs/knob_values.dart`)

Read-only typed accessor over the controller map.

```dart
class KnobValues {
  double getDouble(String id);
  int getInt(String id);
  bool getBool(String id);
  String getString(String id);
  Color getColor(String id);
  T getEnum<T>(String id);
  T valueOf<T>(Knob<T> knob); // pass-by-knob alternative
}
```

### 3.3 `CatalogEntry.live` (`lib/src/models/catalog_entry.dart`)

New named constructor, additive. Existing `CatalogEntry(...)` with
`states:` map is preserved.

```dart
CatalogEntry.live({
  required String name,
  String? category,
  required List<Knob> knobs,
  required Widget Function(BuildContext, KnobValues) builder,
  Widget? thumbnail,
  Size previewSize = const Size(390, 844),
});
```

Internally stores `List<Knob>? knobs` and a `builder` field. Detail screen
branches on `entry.knobs != null`.

### 3.4 `CatalogApp` (breaking)

```dart
CatalogApp({
  required List<CatalogEntry> Function() entries,
  ThemeData? lightTheme,
  ThemeData? darkTheme,
  String title,
  ThemeMode initialTheme,
});
```

Callsite migration: `CatalogApp(entries: buildCatalog)` (drop parens).

## 4. Internal Architecture

### 4.1 `KnobController` (`lib/src/knobs/knob_controller.dart`)

A `ChangeNotifier` holding `Map<String, Object?> _values` plus the current
`List<Knob>`. Responsibilities:

- `set(id, value)` — writes value and calls `notifyListeners()`.
- `reset(id)` — writes `defaultValue` for that knob.
- `resetAll()` — writes defaults for every current knob.
- `reconcile(List<Knob> next)` — called when the knob list changes on hot
  reload. Drops ids absent from `next`, inserts new ids with their defaults,
  keeps matching ids' existing values even when the default has changed. The
  reset buttons surface updated defaults explicitly.

Exposed as read-only via `KnobValues(controller)`.

### 4.2 `DetailScreen` rewrite

- Takes `CatalogEntry Function() entryBuilder` instead of `CatalogEntry entry`.
- `_DetailScreenState`:
  - `late CatalogEntry _entry = widget.entryBuilder();`
  - `late final KnobController _knobs = KnobController(_entry.knobs ?? const []);`
  - Overrides `reassemble()` to re-invoke `entryBuilder()`,
    call `_knobs.reconcile(_entry.knobs ?? const [])`, then `setState(() {})`.
- Body layout when `_entry.knobs != null`:
  - `Expanded(flex: 3, child: previewArea)`
  - `Divider` (fixed; draggable split deferred).
  - `Expanded(flex: 2, child: KnobPanel(controller: _knobs, knobs: _entry.knobs!))`.
- Preview wraps the builder call in
  `ListenableBuilder(listenable: _knobs, builder: (ctx, _) => _entry.builder!(ctx, KnobValues(_knobs)))`.
- Legacy path (`knobs == null`) is unchanged: variant picker + states map.

### 4.3 `KnobPanel` (`lib/src/widgets/knob_panel.dart`)

A `ListView` of typed rows, one per knob, plus a header with a global "Reset
all" action. Row widgets live under `lib/src/widgets/knob_rows/`:

- `DoubleRow` — `Slider` + numeric readback.
- `IntRow` — discrete `Slider` / stepper.
- `BoolRow` — `Switch`.
- `StringRow` — `TextField` with debounce on change.
- `EnumRow` — `DropdownButton<T>`.
- `ColorRow` — swatch strip; full picker deferred.

### 4.4 `GridScreen`

Takes `entriesBuilder` and invokes it in `build()`, so added or removed entries
appear on hot reload.

## 5. Hot-Reload Strategy

Three layers re-run on reload:

1. **Entry list:** `GridScreen.build()` invokes `widget.entriesBuilder()` each
   frame; new/removed entries surface immediately.
2. **Entry internals:** `State.reassemble()` is called by Flutter on every hot
   reload. `DetailScreen` reassemble re-invokes `entryBuilder()`, producing a
   fresh `CatalogEntry` with the edited knob list + defaults, then reconciles
   the controller.
3. **Widget tree:** the `builder: (ctx, v) => MyWidget(...)` closure runs each
   `ListenableBuilder` rebuild. No `const` inside the builder body so literal
   tweaks apply immediately.

Value-preservation policy on reload: match by knob `id`. Existing id with
compatible type keeps the user's value. New id seeds with default. Removed id
is dropped. Changed default on persisting id keeps the user's value; the per-
knob and panel-level reset buttons are the explicit way to see the new
default.

## 6. ValueKeys (Marionette-ready)

All knob surface widgets expose stable keys in the existing `wl.*` namespace:

- Panel root: `wl.detail.knob_panel`
- Row: `wl.detail.knob.<id>`
- Control: `wl.detail.knob.<id>.control`
- Readback label: `wl.detail.knob.<id>.value`
- Per-knob reset: `wl.detail.knob.<id>.reset`
- Global reset: `wl.detail.knobs.reset_all`

## 7. File-by-File Diff Sketch

**New:**

- `lib/src/knobs/knob.dart`
- `lib/src/knobs/knob_controller.dart`
- `lib/src/knobs/knob_values.dart`
- `lib/src/widgets/knob_panel.dart`
- `lib/src/widgets/knob_rows/double_row.dart`
- `lib/src/widgets/knob_rows/int_row.dart`
- `lib/src/widgets/knob_rows/bool_row.dart`
- `lib/src/widgets/knob_rows/string_row.dart`
- `lib/src/widgets/knob_rows/enum_row.dart`
- `lib/src/widgets/knob_rows/color_row.dart`
- `test/knob_controller_test.dart`
- `test/knob_panel_test.dart`
- `test/catalog_entry_live_test.dart`

**Modified:**

- `lib/src/models/catalog_entry.dart` — add `.live` ctor, `List<Knob>? knobs`,
  `Widget Function(BuildContext, KnobValues)? builder`.
- `lib/src/catalog_app.dart` — `entries` becomes
  `List<CatalogEntry> Function()`.
- `lib/src/screens/grid_screen.dart` — accept builder; invoke in `build()`.
- `lib/src/screens/detail_screen.dart` — take `CatalogEntry Function()`,
  `reassemble` hook, conditional knob layout, `ListenableBuilder` wrapping
  the preview.
- `lib/widget_library.dart` — export knob types and `KnobValues`.
- `example/lib/catalog.dart` — migrate "Primary Button" to `.live`. Chip stays
  string-keyed to prove the additive path.
- `example/lib/main.dart` — `CatalogApp(entries: buildCatalog)` (drop parens).

## 8. Migration Reference (Primary Button)

```dart
CatalogEntry.live(
  name: 'Primary Button',
  category: 'Buttons',
  knobs: const [
    StringKnob(id: 'label', label: 'Label', defaultValue: 'Tap me'),
    BoolKnob(id: 'enabled', label: 'Enabled', defaultValue: true),
    BoolKnob(id: 'loading', label: 'Loading', defaultValue: false),
  ],
  builder: (ctx, v) => PrimaryButton(
    label: v.getString('label'),
    enabled: v.getBool('enabled'),
    loading: v.getBool('loading'),
  ),
),
```

Dev loop verification: change `defaultValue: 'Tap me'` to `'Submit'`, save,
hot reload. The panel shows the new default for users who have not dragged
that knob; the live preview reflects it.

## 9. Testing

Unit:

- `knob_controller_test.dart` — `reconcile` retains matching ids, drops
  removed, seeds added, preserves user value across default change.
- `catalog_entry_live_test.dart` — `.live` ctor normalizes internal shape; the
  legacy constructor is unchanged.

Widget:

- `knob_panel_test.dart` — pump `DetailScreen` with a `.live` entry; drive a
  `DoubleKnob` slider via `WidgetTester.drag`; assert the preview rebuilt
  with the new value (probe via `find.byKey` on the rendered widget or a
  test-only exposed value).
- Legacy `states` entry still renders the variant picker and states map
  (regression check).
- Hot-reload simulation: swap `entryBuilder` return value, call `reassemble`,
  assert new defaults surface while existing user-set values are preserved.

Marionette-ready keys verified by a panel test locating controls via
`find.byKey(ValueKey('wl.detail.knob.<id>.control'))`.

## 10. Out of Scope

- Persisting knob state across app restart.
- URL-shareable knob configurations.
- Drag-resizable split handle between preview and panel.
- Migrating entries beyond "Primary Button" in the example app.
- Replacing `widget_library` with the `widgetbook` pub package.

## 11. Open Questions

None blocking. Deferred items tracked in §10.
