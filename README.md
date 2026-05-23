# widget_library

Personal Flutter widget viewer. Drop-in shell to browse widgets and their states without leaving the codebase.

Alternative to Widgetbook with simpler mobile-first navigation: 2-col grid, persistent search, segmented state picker, light/dark toggle.

## What it is

`widget_library` is a Flutter package exposing one widget — `CatalogApp` — that you feed a builder returning `CatalogEntry` objects. Each entry is either a fixed set of named states or a set of **live knobs** (sliders, toggles, dropdowns, text, color, enum) that rebuild the preview in real time. It renders a grid, detail view, search, theme toggle, and knob panel around your widgets. No device frames, no codegen, no persistence.

## What it is not

- Not a production dependency. It is a dev-time viewer.
- Not a design system. All colors and typography come from the `ThemeData` you pass in.
- Not Widgetbook. Less powerful, fewer surprises.

## Integration

Two patterns. Pick based on whether your app already has platform scaffolding.

### Pattern A: dev_dependency (recommended for existing apps)

If your app already has configured `android/` + `ios/` dirs (desugaring, signing, google-services, `.env` assets, min SDK), reuse them. Add `widget_library` as a **dev dependency** and run the catalog via `-t`:

```yaml
# my_app/pubspec.yaml
dev_dependencies:
  widget_library:
    git:
      url: https://github.com/RaiserSoftwareInc/WidgetLibrary.git
      ref: main
```

Catalog entry file:

```
my_app/
├── lib/                      # prod code — never imports widget_library
└── tool/
    └── catalog/
        ├── main.dart         # CatalogApp entry
        ├── catalog.dart      # List<CatalogEntry>
        └── entries/          # one file per widget
```

**`tool/catalog/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';
import 'package:my_app/theme.dart';
import 'catalog.dart';

void main() => runApp(CatalogApp(
  entriesBuilder: buildCatalog,       // function reference — hot-reload safe
  lightTheme: appLight,
  darkTheme: appDark,
));
```

**Run the viewer:** `flutter run -t tool/catalog/main.dart`
**Build prod (unaffected):** `flutter build apk`

Safety: `widget_library` is only imported from `tool/`, never from `lib/`. Tree-shaking strips it and its transitive code from release binaries. `widget_library` has no production deps beyond the Flutter SDK, so lockfile impact is marginal.

### Pattern B: separate tool package

If you want stronger isolation — no test/lint runs touching `widget_library`, fully separate lockfile — use a sub-project. This forces you to duplicate platform config (Gradle desugaring, signing, google-services, asset bundles) that your main app already has. Only worth it if you don't have them yet.

```
my_app/
├── pubspec.yaml              # prod deps only — no widget_library here
└── tools/
    └── catalog/
        ├── pubspec.yaml      # depends on widget_library + ../.. (your app)
        ├── lib/
        │   ├── main.dart
        │   └── catalog.dart
        ├── android/          # separate Gradle scaffold — mirror host config
        └── ios/              # separate Xcode project
```

**`tools/catalog/pubspec.yaml`:**

```yaml
name: my_app_catalog
publish_to: none
environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  my_app:
    path: ../..
  widget_library:
    git:
      url: https://github.com/RaiserSoftwareInc/WidgetLibrary.git
      ref: main
```

Then `cd tools/catalog && flutter create --platforms=android,ios .` to generate platform dirs, and re-apply any Gradle config your host app needs (desugaring, signing, etc). Run via `cd tools/catalog && flutter run`.

### Which to pick

|                 | Pattern A (dev_dependency)          | Pattern B (tool package)   |
| --------------- | ----------------------------------- | -------------------------- |
| Platform config | inherited from host app             | must duplicate             |
| Lockfile        | one (host's) gains `widget_library` | isolated                   |
| Setup friction  | minimal                             | high                       |
| Leak risk       | none (tree-shaken)                  | none                       |
| Use when        | host app already configured         | greenfield / strict isolation |

## Registering widgets

`CatalogApp` accepts two shapes (provide exactly one):

- `entriesBuilder: List<CatalogEntry> Function()` — **recommended.** Pass the reference, not a call. The shell invokes it on every build so hot reload picks up edits to defaults and entry lists without a full restart.
- `entries: List<CatalogEntry>` — legacy 0.5.x call site (`entries: buildCatalog()`). Deprecated; hot reload will NOT pick up edits to entry defaults without a full restart. Removed in 1.0.0.

Each entry is one of two flavors: **legacy** (fixed named states) or **live** (typed knobs wired to a builder).

### Legacy: fixed states

```dart
// tool/catalog/catalog.dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';
import 'package:my_app/widgets/primary_button.dart';
import 'package:my_app/widgets/user_card.dart';

List<CatalogEntry> buildCatalog() => [
  CatalogEntry(
    name: 'Primary Button',
    category: 'Buttons',
    states: {
      'default':  (_) => const PrimaryButton(label: 'OK'),
      'disabled': (_) => const PrimaryButton(label: 'OK', enabled: false),
      'loading':  (_) => const PrimaryButton(label: 'OK', loading: true),
    },
  ),
  CatalogEntry(
    name: 'User Card',
    category: 'Surfaces',
    states: {
      'loaded':  (_) => UserCard(user: mockUser),
      'loading': (_) => const UserCard.skeleton(),
      'error':   (_) => const UserCard.error(),
    },
  ),
];
```

Rules:
- `name` — required. Shown on the grid tile and detail AppBar.
- `states` — required, non-empty `Map<String, WidgetBuilder>`. Keys are shown in the variant picker; insertion order is preserved.
- `category` — optional. When at least one entry sets it, a filter chip strip appears above the grid. Otherwise hidden.
- `thumbnail` — optional `Widget`. When absent, the tile auto-renders the first state via `FittedBox`.
- `previewSize` — optional `Size`, defaults to `Size(390, 844)`. Virtual viewport given to the widget when rendered. Widgets using `double.infinity`, `Stack(fit: expand)`, or full-bleed patterns resolve against these bounds instead of an infinite canvas. Override per-entry for widgets with a different natural footprint (e.g. a 120-px-wide tile).

### Live: typed knobs

Declare typed controls next to the preview. Dragging a slider (or toggling a switch, changing a dropdown, typing a string, picking a color, selecting an enum) rebuilds the preview live:

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
);
```

Knob types: `DoubleKnob` (slider, `min`/`max`/optional `step`), `IntKnob` (discrete slider), `BoolKnob` (switch), `StringKnob` (text field, optional `hint`), `EnumKnob<T>` (dropdown over `values`, optional `labelOf`), `ColorKnob` (swatch strip, optional `swatches`). Each knob has a unique `id` read back via `KnobValues` (`v.getDouble(id)`, `v.getBool(id)`, `v.getEnum<T>(id)`, etc.).

**Hot reload:** edit a `defaultValue` in your entry file and save. The shell re-invokes `buildCatalog`, reconciles the knob list, keeps any user-dragged values on matching ids, and seeds defaults for new ids. Use the in-panel `Reset` button to surface a changed default on a knob you've already moved.

**Nullable parameters:** pair a `BoolKnob` with a value knob and branch in the builder:

```dart
knobs: const [
  BoolKnob(id: 'autoInset', label: 'Auto safe-area', defaultValue: true),
  DoubleKnob(id: 'topInset', label: 'Top inset', defaultValue: 24, min: 0, max: 80),
],
builder: (ctx, v) => AtlasHeader(
  topInset: v.getBool('autoInset') ? null : v.getDouble('topInset'),
);
```

Live and legacy entries coexist in the same catalog — the shell branches on the entry type, so you can migrate one widget at a time.

### Step-by-step: add knobs to a widget

Use this recipe to convert any widget entry from fixed `states` to live tweakable controls.

**1. Identify the parameters you want to expose.** Look at your widget's constructor. Each public `required` or named param is a candidate knob. Skip params derived from context (theme, localization, controllers) — those aren't knob material.

Example — `PrimaryButton`:

```dart
class PrimaryButton extends StatelessWidget {
  final String label;      // → StringKnob
  final bool enabled;      // → BoolKnob
  final bool loading;      // → BoolKnob
  final VoidCallback? onTap; // skip — behavior, not visual state
}
```

**2. Pick the right knob type per parameter.**

| Parameter shape | Knob |
|---|---|
| `double` (continuous range: height, padding, radius, opacity) | `DoubleKnob(min:, max:, step: optional)` |
| `int` (counts, line limits) | `IntKnob(min:, max:, step: 1)` |
| `bool` (on/off flags) | `BoolKnob` |
| `String` (label, hint, placeholder) | `StringKnob(hint: optional)` |
| `enum` or fixed value set | `EnumKnob<T>(values: [...], labelOf: optional)` |
| `Color` (backgrounds, tints, borders) | `ColorKnob(swatches: optional)` |
| Nullable value (e.g. `double?`) | `BoolKnob` toggle + value knob; branch in builder |

**3. Give each knob a stable `id`.** Use the constructor parameter name (`label`, `enabled`). The id is what the builder reads and what reconcile uses to preserve user-dragged values across hot reloads. Renaming an id counts as removing the old knob and adding a new one.

**4. Convert the entry.** Replace `CatalogEntry(name:, states:)` with `CatalogEntry.live(name:, knobs:, builder:)`:

```dart
// Before
CatalogEntry(
  name: 'Primary Button',
  states: {
    'default':  (_) => const PrimaryButton(label: 'OK'),
    'disabled': (_) => const PrimaryButton(label: 'OK', enabled: false),
    'loading':  (_) => const PrimaryButton(label: 'OK', loading: true),
  },
),

// After
CatalogEntry.live(
  name: 'Primary Button',
  knobs: const [
    StringKnob(id: 'label', label: 'Label', defaultValue: 'OK'),
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

`KnobValues` read methods: `getDouble`, `getInt`, `getBool`, `getString`, `getColor`, `getEnum<T>`, plus `valueOf(knob)` if you hold the `Knob` instance.

**5. Switch to `entriesBuilder:` (once).** In `main.dart`, pass the catalog as a function reference so hot reload can re-run it:

```dart
runApp(CatalogApp(entriesBuilder: buildCatalog));   // not buildCatalog()
```

**6. Run and verify.** `flutter run -t tool/catalog/main.dart`. Open the entry. The panel renders below the preview. Drag / toggle / type — preview rebuilds live.

**7. Tweak defaults with hot reload.** Edit any `defaultValue` in your entry file, save, press `r`. Knobs you haven't moved surface the new default; knobs you've dragged keep your value (use per-knob Reset to see the new default). No restart.

**Picking ranges.** For `DoubleKnob` / `IntKnob`, pick `min`/`max` with ~2× your expected use range. Tight ranges feel sluggish; too-wide ranges make small adjustments fiddly. Use `step:` only when discrete increments matter (snap to 4dp grid, integer-only values).

**Pitfalls.**
- Ids must be unique per entry. Duplicates overwrite.
- Changing a knob's type (e.g. `DoubleKnob` → `IntKnob`) with the same id on hot reload throws `StateError` — rename the id, or restart the app.
- `const` on the `knobs:` list is required for the analyzer to treat knob instances as compile-time constants. Most knob fields (`min`, `max`, `defaultValue`, option lists) must be const-expressions too.

### Migrating from 0.5.x

Classic `entries: buildCatalog()` still works (wrapped internally, `@Deprecated`). For hot-reload-safe registration rename to `entriesBuilder` and drop the parens:

```dart
// 0.5.x (still works via deprecated entries:)
runApp(CatalogApp(entries: buildCatalog()));

// 0.6.1+ (recommended)
runApp(CatalogApp(entriesBuilder: buildCatalog));
```

See [MIGRATION.md](MIGRATION.md) and [CHANGELOG.md](CHANGELOG.md).

## Theming

`CatalogApp` takes optional `lightTheme` and `darkTheme` `ThemeData`. Pass your real app themes:

```dart
CatalogApp(
  entries: buildCatalog,
  lightTheme: appLight,
  darkTheme: appDark,
);
```

Shell surfaces read `Theme.of(context).colorScheme.*` (surface, surfaceContainerLow, outlineVariant, onSurfaceVariant, etc.) and `textTheme.*`. Component themes (`appBarTheme`, `filterChipTheme`, `segmentedButtonTheme`, `cardTheme`) are respected.

If you omit themes, defaults are `ThemeData.light(useMaterial3: true)` and `ThemeData.dark(useMaterial3: true)`.

### Initial mode

`CatalogApp` takes an optional `initialTheme` param that controls which mode the viewer starts in:

```dart
CatalogApp(
  entries: buildCatalog,
  lightTheme: appLight,
  darkTheme: appDark,
  initialTheme: ThemeMode.system,  // default — follows OS at boot
);
```

- `ThemeMode.system` (default) — resolves to light/dark based on `PlatformDispatcher.platformBrightness` at boot
- `ThemeMode.light` / `ThemeMode.dark` — explicit override

The in-app toggle always flips between light and dark regardless of `initialTheme`.

## Shell behavior

- **Grid** — 2-col tiles. Preview on `surfaceContainerLow`, name + state-count badge on separator footer.
- **Search** — persistent bar under AppBar. Case-insensitive substring match on `name`.
- **Category filter** — chip strip, only shown when any entry defines a category.
- **Theme toggle** — AppBar action, flips light/dark in-memory (no persistence).
- **Detail** — legacy entries: `SegmentedButton` for ≤4 states, scrolling chip strip for >4. Live entries: inline split — preview on top (flex 3), knob panel below (flex 2) — with per-knob Reset and a global Reset-all action.
- **Error handling** — `ErrorBoundary` wraps each state preview. A throwing builder renders inline error text + stack trace instead of crashing the viewer.
- **Empty state** — copy-paste `CatalogEntry(...)` sample snippet.
- **Specs panel** — tap the info icon in the detail AppBar to open a bottom sheet showing the preview's laid-out size, active theme tokens (colors + text styles), and a depth-limited widget tree with diagnostic properties. Useful for inspecting what a widget is actually composed of. Custom widgets show richer data when they override `debugFillProperties`.

## Agent automation (Marionette)

The shell is keyed for use with [Marionette MCP](https://marionette.leancode.co/) so an AI agent can drive the viewer: search, filter, open entries, switch states, toggle theme, read specs, take screenshots.

**Consumer setup** (Pattern A shown; same idea for Pattern B):

```yaml
# my_app/pubspec.yaml
dev_dependencies:
  marionette_flutter: ^0.5.0
  marionette_mcp: ^0.5.0
```

```dart
// tool/catalog/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:widget_library/widget_library.dart';
import 'catalog.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(CatalogApp(entries: buildCatalog));
}
```

Run `flutter run -t tool/catalog/main.dart` in debug mode, copy the VM service `ws://...` URL from the output, point your agent's MCP config at `dart run marionette_mcp`.

**Keys exposed by the shell** (all `wl.*` namespaced):

| Surface | Key |
| --- | --- |
| Search field | `wl.search_field` |
| Category chip | `wl.category_chip.<category>` |
| Grid tile | `wl.grid_tile.<entry_name>` |
| Theme toggle (both screens) | `wl.app_bar.theme_toggle` |
| Specs button | `wl.app_bar.specs` |
| Variant segment / chip | `wl.detail.variant.<state_key>` |
| Knob panel root | `wl.detail.knob_panel` |
| Knob row | `wl.detail.knob.<id>` |
| Knob control (slider / switch / dropdown / text / swatch strip) | `wl.detail.knob.<id>.control` |
| Knob readback (current value as text) | `wl.detail.knob.<id>.value` |
| Knob reset | `wl.detail.knob.<id>.reset` |
| Reset all knobs | `wl.detail.knobs.reset_all` |
| Empty-state copy button | `wl.empty_state.copy` |
| Grid screen root | `wl.grid_screen` |
| Detail screen root | `wl.detail_screen` |
| No-matches state | `wl.grid.no_matches` |
| Result count (visible label) | `wl.grid.result_count` |

**Your own widgets** need their own keys (e.g. `ValueKey('submit_button')`) for an agent to interact with them. The shell handles the navigation chrome; catalog entries handle their own.

## Hot reload

Catalog entries are plain Dart. Edit `catalog.dart` or any registered widget, save, press `r` in the `flutter run` terminal. No build step, no regen.

## Platforms

Mobile only (Android + iOS). Desktop and web are out of scope.

## Constraints

Intentional YAGNI:
- No device/viewport preview frames.
- No code generation or annotations.
- No persistence of theme choice or knob values across restarts.
- No URL-shareable knob configurations.
- No draggable split handle between preview and knob panel.
- No golden tests.
- No pub.dev release.

If you hit a wall, fork it — it is ~500 LOC.

## Development

```bash
flutter analyze        # clean
flutter test           # full suite
cd example
flutter run            # run the sample catalog on a device
```

## License

Private. Not for redistribution.
