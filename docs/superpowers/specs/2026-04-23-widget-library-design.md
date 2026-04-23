# Widget Library — Design Spec

**Date:** 2026-04-23
**Author:** Bryan Shetty
**Status:** Approved for planning

## Goal

Personal Flutter widget viewer package. Browse widgets and their states on mobile. Alternative to Widgetbook with simpler layout and navigation. Not for public release.

## Scope

### In scope
- Browse registered widgets from a grid
- View multiple states per widget (default, loading, empty, error, etc.)
- Light/dark theme toggle
- Search widgets by name
- Mobile (iOS/Android) target platform

### Out of scope (YAGNI)
- Knobs / live prop tweaking
- Device/size preview frames
- Desktop or web builds
- Code generation / annotations
- Shared preferences / persistence of theme choice
- Golden tests
- Public pub.dev release

## Architecture

Monorepo-style layout: reusable viewer package + example app that registers personal widgets.

```
widget_library/                 # package — reusable viewer shell
  lib/
    widget_library.dart         # barrel export
    src/
      catalog_app.dart          # root MaterialApp
      models/
        catalog_entry.dart      # CatalogEntry data class
      screens/
        grid_screen.dart        # home grid + search
        detail_screen.dart      # chip selector + preview
      theme/
        theme_controller.dart   # ValueNotifier<ThemeMode>
      widgets/
        error_boundary.dart     # catches builder exceptions
  test/                         # widget tests for shell
  pubspec.yaml

example/                        # personal catalog app
  lib/
    main.dart                   # runApp(CatalogApp(entries: ...))
    catalog.dart                # hand-written List<CatalogEntry>
    widgets/                    # actual widgets under test
  pubspec.yaml                  # depends on ../widget_library via path
```

Viewer shell has zero knowledge of specific widgets. Example app wires up entries, themes, and runs the app. Path dependency keeps feedback loop instant (hot reload works across both).

## Public API

```dart
class CatalogEntry {
  final String name;
  final String? category;
  final Map<String, WidgetBuilder> states;
  final Widget? thumbnail;
  const CatalogEntry({
    required this.name,
    required this.states,
    this.category,
    this.thumbnail,
  });
}

class CatalogApp extends StatelessWidget {
  final List<CatalogEntry> entries;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final String title;
  const CatalogApp({
    super.key,
    required this.entries,
    this.lightTheme,
    this.darkTheme,
    this.title = 'Widget Library',
  });
}
```

### Registration example

```dart
void main() => runApp(CatalogApp(
  entries: [
    CatalogEntry(
      name: 'Primary Button',
      states: {
        'default':  (_) => const PrimaryButton(label: 'Tap'),
        'disabled': (_) => const PrimaryButton(label: 'Tap', enabled: false),
        'loading':  (_) => const PrimaryButton(label: 'Tap', loading: true),
      },
    ),
  ],
  lightTheme: appLight,
  darkTheme: appDark,
));
```

Manual `List<CatalogEntry>` chosen over codegen or convention scanning. Rationale: zero dependencies, hot reload works natively on Dart edits, no build step lag, trivial to understand.

## Screens

### GridScreen (home)
- AppBar: title, theme toggle icon, search icon
- Body: 2-column `GridView` of entries
- Tile: thumbnail if provided, else auto-rendered first state inside `FittedBox`; name label underneath
- Search: tapping icon expands `TextField` in AppBar; filters entries by case-insensitive substring match on `name`
- Tap tile → push `DetailScreen(entry)`
- Empty entries list → centered empty-state message

### DetailScreen
- AppBar: back, entry name, theme toggle icon
- Top strip: horizontal scrolling row of `ChoiceChip`s, one per state key; selected chip drives render
- Body: `Center` + `Padding` wrapping currently selected state builder
- Local `StatefulWidget` holds `selectedStateKey: String` (initially first key)
- Entry with empty states map → "No states" message (also asserted in debug)

### Theme toggle
- Root-level `ValueNotifier<ThemeMode>` exposed via `InheritedWidget` (simple `CatalogTheme.of(context).notifier`)
- `MaterialApp` wrapped in `ValueListenableBuilder` reading that notifier to drive `themeMode`
- Appbar icon button flips between `ThemeMode.light` and `ThemeMode.dark`
- In-memory only

## Error Handling

- Empty entries list → grid shows friendly empty state, does not crash
- Entry with empty states map → `assert` in debug; UI shows "No states defined" placeholder in release
- Builder throws → `ErrorBoundary` widget wraps each preview render; on exception, shows error text + stack trace inline instead of white screen
- No global error reporting / telemetry

## Testing

Widget tests (`flutter_test`) for the shell only:

- Grid renders entries passed in
- Search filters grid by name substring
- Tapping tile navigates to DetailScreen
- DetailScreen renders initial state builder
- Tapping different chip swaps rendered state
- Theme toggle flips `ThemeMode` at root

No tests for consumer widgets registered in the example app — that is the consumer's concern.

## Dependencies

Package `widget_library/pubspec.yaml`:
- `flutter` (SDK)
- `flutter_test` (dev, SDK)

No third-party runtime dependencies. Intentional.

## Non-goals

- Not optimizing for large catalogs (hundreds of widgets). If personal catalog grows beyond comfort, revisit with categories/tree nav.
- Not shipping to pub.dev. Path dependency is fine.
