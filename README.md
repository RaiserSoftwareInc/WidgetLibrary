# widget_library

Personal Flutter widget viewer. Drop-in shell to browse widgets and their states without leaving the codebase.

Alternative to Widgetbook with simpler mobile-first navigation: 2-col grid, persistent search, segmented state picker, light/dark toggle.

## What it is

`widget_library` is a Flutter package exposing one widget — `CatalogApp` — that you feed a list of `CatalogEntry` objects (widget + named states). It renders a grid, detail view, search, and theme toggle around your widgets. That's it. No knobs, no device frames, no codegen, no persistence.

## What it is not

- Not a production dependency. It is a dev-time viewer.
- Not a design system. All colors and typography come from the `ThemeData` you pass in.
- Not Widgetbook. Less powerful, fewer surprises.

## Install

Add as a dev-time dependency in a separate tool package (see [Integration](#integration) below). Do not add to your app's production `pubspec.yaml`.

```yaml
dependencies:
  widget_library:
    git:
      url: https://github.com/RaiserSoftwareInc/WidgetLibrary.git
      ref: main
```

## Integration

Use the **tool package pattern** to keep the viewer completely out of production builds.

```
my_app/
├── pubspec.yaml              # prod deps only — no widget_library here
├── lib/
│   ├── main.dart             # prod entry
│   ├── theme.dart            # shared appLight / appDark
│   └── widgets/              # reusable widgets
└── tools/
    └── catalog/
        ├── pubspec.yaml      # depends on widget_library + ../.. (your app)
        ├── lib/
        │   ├── main.dart     # catalog entry
        │   └── catalog.dart  # List<CatalogEntry>
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

**`tools/catalog/lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';
import 'package:my_app/theme.dart';
import 'catalog.dart';

void main() => runApp(CatalogApp(
  entries: buildCatalog(),
  lightTheme: appLight,
  darkTheme: appDark,
));
```

**Run the viewer:** `cd tools/catalog && flutter run`
**Build prod (unaffected):** `cd my_app && flutter build apk`

The prod app's `pubspec.yaml` never references `widget_library`, so the package cannot leak into release binaries.

## Registering widgets

Each entry names a widget and maps named states to builders:

```dart
// tools/catalog/lib/catalog.dart
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

## Theming

`CatalogApp` takes optional `lightTheme` and `darkTheme` `ThemeData`. Pass your real app themes:

```dart
CatalogApp(
  entries: buildCatalog(),
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
  entries: buildCatalog(),
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
- **Detail** — `SegmentedButton` for ≤4 states, scrolling chip strip for >4.
- **Error handling** — `ErrorBoundary` wraps each state preview. A throwing builder renders inline error text + stack trace instead of crashing the viewer.
- **Empty state** — copy-paste `CatalogEntry(...)` sample snippet.

## Hot reload

Catalog entries are plain Dart. Edit `catalog.dart` or any registered widget, save, press `r` in the `flutter run` terminal. No build step, no regen.

## Platforms

Mobile only (Android + iOS). Desktop and web are out of scope.

## Constraints

Intentional YAGNI:
- No knobs or live prop tweaking.
- No device/viewport preview frames.
- No code generation or annotations.
- No persistence of theme choice.
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
