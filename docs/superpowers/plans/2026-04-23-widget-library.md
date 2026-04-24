# Widget Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a personal Flutter widget viewer package (`widget_library`) with a grid-based mobile UI, per-widget state switching via chips, and light/dark theme toggle. Ship a path-dependent `example/` app that registers sample widgets.

**Architecture:** Reusable Flutter package exposes a root `CatalogApp` that consumes a `List<CatalogEntry>`. A `ValueNotifier<ThemeMode>` lifted to the root drives `MaterialApp.themeMode`. Two screens: `GridScreen` (home, searchable grid) and `DetailScreen` (chip state selector + single preview). An `ErrorBoundary` widget catches exceptions thrown by entry state builders so bad widgets don't crash the viewer.

**Tech Stack:** Flutter SDK, Dart null-safe, `flutter_test` for widget tests. No third-party runtime deps.

---

## File Structure

```
widget_library/                        # package root (existing git repo root)
  pubspec.yaml
  analysis_options.yaml
  lib/
    widget_library.dart                # barrel export
    src/
      catalog_app.dart                 # root MaterialApp + InheritedWidget wiring
      models/
        catalog_entry.dart             # CatalogEntry value class
      theme/
        theme_controller.dart          # CatalogTheme InheritedWidget + ValueNotifier<ThemeMode>
      widgets/
        error_boundary.dart            # catches builder exceptions
      screens/
        grid_screen.dart               # home: search + 2-col grid
        detail_screen.dart             # chip selector + preview
  test/
    catalog_entry_test.dart
    theme_controller_test.dart
    error_boundary_test.dart
    catalog_app_test.dart
    grid_screen_test.dart
    detail_screen_test.dart
  example/
    pubspec.yaml                       # path dep on ../
    lib/
      main.dart                        # runApp(CatalogApp(entries: buildCatalog()))
      catalog.dart                     # hand-written List<CatalogEntry>
      widgets/
        primary_button.dart            # sample widget for smoke-testing viewer
```

Package root is `D:/code/raiser_software/WidgetLibrary` (already git-initialized, remote set to `origin`).

---

### Task 0: Scaffold Flutter package and example app

**Goal:** Flutter package skeleton in repo root, plus an `example/` app with path dependency, both analyzable.

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/widget_library.dart`
- Create: `example/pubspec.yaml`
- Create: `example/lib/main.dart`

**Acceptance Criteria:**
- [ ] `flutter pub get` succeeds at repo root
- [ ] `flutter pub get` succeeds in `example/`
- [ ] `flutter analyze` passes at repo root with zero issues
- [ ] `example/` can build for Android (`flutter build apk --debug` from `example/`)

**Verify:** `flutter analyze` at root → `No issues found!`

**Steps:**

- [ ] **Step 1: Create the package `pubspec.yaml`**

File: `pubspec.yaml`
```yaml
name: widget_library
description: Personal Flutter widget viewer with grid navigation and state switching.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
```

- [ ] **Step 2: Create `analysis_options.yaml`**

File: `analysis_options.yaml`
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    require_trailing_commas: true
```

- [ ] **Step 3: Create the barrel export with a placeholder**

File: `lib/widget_library.dart`
```dart
library widget_library;

// Public API exports are added in later tasks.
```

- [ ] **Step 4: Scaffold the example app**

Run from repo root:
```bash
flutter create --platforms=android,ios --project-name widget_library_example example
```
Expected: `All done!` printed, `example/` populated.

- [ ] **Step 5: Overwrite `example/pubspec.yaml` to depend on the parent package**

File: `example/pubspec.yaml`
```yaml
name: widget_library_example
description: Example/host app for the widget_library package.
publish_to: none
version: 0.1.0

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  widget_library:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 6: Replace `example/lib/main.dart` with a stub that imports the package**

File: `example/lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Scaffolded')))));
}
```
(Real wiring lands in Task 7. The import proves the path dep resolves.)

- [ ] **Step 7: Resolve dependencies and analyze**

Run:
```bash
flutter pub get
cd example && flutter pub get && cd ..
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml analysis_options.yaml lib/ example/
git commit -m "chore: scaffold widget_library package and example app"
```

---

### Task 1: `CatalogEntry` model

**Goal:** Immutable data class describing one widget plus its named states.

**Files:**
- Create: `lib/src/models/catalog_entry.dart`
- Test: `test/catalog_entry_test.dart`

**Acceptance Criteria:**
- [ ] `CatalogEntry` constructible with required `name` and `states`
- [ ] `states` is a `Map<String, WidgetBuilder>` exposing insertion order
- [ ] Optional `category` and `thumbnail` default to `null`
- [ ] Debug assertion fires when `states` is empty

**Verify:** `flutter test test/catalog_entry_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Write the failing test**

File: `test/catalog_entry_test.dart`
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/models/catalog_entry.dart';

void main() {
  group('CatalogEntry', () {
    test('stores name, states, and preserves insertion order', () {
      final entry = CatalogEntry(
        name: 'Button',
        states: {
          'default': (_) => const SizedBox(),
          'disabled': (_) => const SizedBox(),
        },
      );

      expect(entry.name, 'Button');
      expect(entry.states.keys.toList(), ['default', 'disabled']);
      expect(entry.category, isNull);
      expect(entry.thumbnail, isNull);
    });

    test('accepts optional category and thumbnail', () {
      final entry = CatalogEntry(
        name: 'Chip',
        category: 'Inputs',
        thumbnail: const Icon(IconData(0xe000)),
        states: {'default': (_) => const SizedBox()},
      );

      expect(entry.category, 'Inputs');
      expect(entry.thumbnail, isA<Icon>());
    });

    test('asserts when states map is empty in debug builds', () {
      expect(
        () => CatalogEntry(name: 'Empty', states: const {}),
        throwsAssertionError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to see it fail**

Run: `flutter test test/catalog_entry_test.dart`
Expected: FAIL — file `catalog_entry.dart` not found.

- [ ] **Step 3: Implement `CatalogEntry`**

File: `lib/src/models/catalog_entry.dart`
```dart
import 'package:flutter/widgets.dart';

@immutable
class CatalogEntry {
  final String name;
  final String? category;
  final Map<String, WidgetBuilder> states;
  final Widget? thumbnail;

  CatalogEntry({
    required this.name,
    required Map<String, WidgetBuilder> states,
    this.category,
    this.thumbnail,
  })  : assert(states.isNotEmpty, 'CatalogEntry.states must not be empty'),
        states = Map.unmodifiable(states);
}
```

- [ ] **Step 4: Export from the barrel**

Edit: `lib/widget_library.dart`
```dart
library widget_library;

export 'src/models/catalog_entry.dart';
```

- [ ] **Step 5: Run tests + analyze**

Run:
```bash
flutter test test/catalog_entry_test.dart
flutter analyze
```
Expected: all tests pass, no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add lib/src/models/catalog_entry.dart lib/widget_library.dart test/catalog_entry_test.dart
git commit -m "feat: add CatalogEntry model"
```

---

### Task 2: `ThemeController` + `CatalogTheme` InheritedWidget

**Goal:** Root-level theme state with a simple API for toggling and reading.

**Files:**
- Create: `lib/src/theme/theme_controller.dart`
- Test: `test/theme_controller_test.dart`

**Acceptance Criteria:**
- [ ] `ThemeController` is a `ValueNotifier<ThemeMode>` with initial value `ThemeMode.light`
- [ ] `toggle()` flips `light ↔ dark`; other modes normalize to `light`
- [ ] `CatalogTheme.of(context)` returns the controller from the nearest ancestor
- [ ] Descendants rebuild when the controller changes (via `ValueListenableBuilder`)

**Verify:** `flutter test test/theme_controller_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Write the failing test**

File: `test/theme_controller_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('defaults to light and toggles between light and dark', () {
      final c = ThemeController();
      expect(c.value, ThemeMode.light);

      c.toggle();
      expect(c.value, ThemeMode.dark);

      c.toggle();
      expect(c.value, ThemeMode.light);
    });

    test('toggle normalizes ThemeMode.system to light', () {
      final c = ThemeController(initial: ThemeMode.system);
      c.toggle();
      expect(c.value, ThemeMode.light);
    });
  });

  group('CatalogTheme.of', () {
    testWidgets('returns the controller provided by the nearest ancestor',
        (tester) async {
      final controller = ThemeController();
      ThemeController? captured;

      await tester.pumpWidget(
        CatalogTheme(
          controller: controller,
          child: Builder(
            builder: (ctx) {
              captured = CatalogTheme.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, same(controller));
    });

    testWidgets('throws a clear error when no ancestor is found',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            expect(() => CatalogTheme.of(ctx), throwsFlutterError);
            return const SizedBox();
          },
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to see it fail**

Run: `flutter test test/theme_controller_test.dart`
Expected: FAIL — `theme_controller.dart` does not exist.

- [ ] **Step 3: Implement controller + InheritedWidget**

File: `lib/src/theme/theme_controller.dart`
```dart
import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({ThemeMode initial = ThemeMode.light}) : super(initial);

  void toggle() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class CatalogTheme extends InheritedNotifier<ThemeController> {
  const CatalogTheme({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<CatalogTheme>();
    if (widget == null) {
      throw FlutterError(
        'CatalogTheme.of() called with a context that does not contain a CatalogTheme.',
      );
    }
    return widget.notifier!;
  }
}
```

- [ ] **Step 4: Run tests + analyze**

Run:
```bash
flutter test test/theme_controller_test.dart
flutter analyze
```
Expected: pass + clean.

- [ ] **Step 5: Commit**

```bash
git add lib/src/theme/theme_controller.dart test/theme_controller_test.dart
git commit -m "feat: add ThemeController and CatalogTheme inherited widget"
```

---

### Task 3: `ErrorBoundary` widget

**Goal:** Render a single child widget; if building it throws, show the error inline instead of crashing the viewer.

**Files:**
- Create: `lib/src/widgets/error_boundary.dart`
- Test: `test/error_boundary_test.dart`

**Acceptance Criteria:**
- [ ] Successful child renders normally
- [ ] Exception thrown by the child's build produces a visible error message containing the exception text
- [ ] Error UI is plain `Text` wrapped in a red-outlined `Container`; no rethrow
- [ ] When the `key` or `builder` changes, the boundary retries

**Verify:** `flutter test test/error_boundary_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Write the failing test**

File: `test/error_boundary_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/widgets/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when builder succeeds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(builder: (_) => const Text('ok')),
        ),
      );
      expect(find.text('ok'), findsOneWidget);
    });

    testWidgets('shows error text when builder throws', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            builder: (_) => throw StateError('boom'),
          ),
        ),
      );
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to see it fail**

Run: `flutter test test/error_boundary_test.dart`
Expected: FAIL — `error_boundary.dart` does not exist.

- [ ] **Step 3: Implement `ErrorBoundary`**

File: `lib/src/widgets/error_boundary.dart`
```dart
import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final WidgetBuilder builder;
  const ErrorBoundary({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context);
    } catch (error, stack) {
      return _ErrorView(error: error, stack: stack);
    }
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final StackTrace stack;
  const _ErrorView({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 1),
        color: Colors.red.withValues(alpha: 0.08),
      ),
      child: SingleChildScrollView(
        child: Text(
          'Widget build failed:\n$error\n\n$stack',
          style: TextStyle(
            color: Colors.red.shade900,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
```

Note: this only catches synchronous exceptions inside the immediate `builder` call. Exceptions from child widgets' own `build` are handled by Flutter's `ErrorWidget.builder`, which is acceptable for this personal tool.

- [ ] **Step 4: Run tests + analyze**

Run:
```bash
flutter test test/error_boundary_test.dart
flutter analyze
```
Expected: pass + clean.

- [ ] **Step 5: Commit**

```bash
git add lib/src/widgets/error_boundary.dart test/error_boundary_test.dart
git commit -m "feat: add ErrorBoundary widget for safe builder rendering"
```

---

### Task 4: `CatalogApp` root widget

**Goal:** Root `MaterialApp` wired with `ThemeController`, consuming entries and navigating to `GridScreen`. This task temporarily renders a placeholder body; `GridScreen` replaces it in Task 5.

**Files:**
- Create: `lib/src/catalog_app.dart`
- Test: `test/catalog_app_test.dart`

**Acceptance Criteria:**
- [ ] `CatalogApp(entries: [])` renders without crashing
- [ ] `CatalogApp` injects a `CatalogTheme` so descendants can read the controller
- [ ] `MaterialApp.themeMode` reflects the controller's current value
- [ ] Custom `lightTheme` and `darkTheme` are passed through to `MaterialApp`

**Verify:** `flutter test test/catalog_app_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Write the failing test**

File: `test/catalog_app_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

void main() {
  testWidgets('CatalogApp builds with empty entries and exposes CatalogTheme',
      (tester) async {
    await tester.pumpWidget(
      const CatalogApp(entries: []),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('CatalogApp.themeMode tracks the ThemeController', (tester) async {
    await tester.pumpWidget(const CatalogApp(entries: []));
    final materialApp1 = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp1.themeMode, ThemeMode.light);

    // Toggle from any descendant's context.
    final ctx = tester.element(find.byType(MaterialApp));
    CatalogTheme.of(ctx).toggle();
    await tester.pump();

    final materialApp2 = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp2.themeMode, ThemeMode.dark);
  });

  testWidgets('CatalogApp passes through lightTheme and darkTheme', (tester) async {
    final light = ThemeData(primarySwatch: Colors.blue);
    final dark = ThemeData.dark();

    await tester.pumpWidget(
      CatalogApp(entries: const [], lightTheme: light, darkTheme: dark),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, same(light));
    expect(app.darkTheme, same(dark));
  });
}
```

Note: `CatalogTheme.of` is not yet exported publicly. Import it from `src/theme/theme_controller.dart` in the test for now; Task 7 decides whether to expose it.

- [ ] **Step 2: Run test to see it fail**

Run: `flutter test test/catalog_app_test.dart`
Expected: FAIL — `CatalogApp` does not exist.

- [ ] **Step 3: Implement `CatalogApp`**

File: `lib/src/catalog_app.dart`
```dart
import 'package:flutter/material.dart';

import 'models/catalog_entry.dart';
import 'theme/theme_controller.dart';

class CatalogApp extends StatefulWidget {
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

  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> {
  final ThemeController _controller = ThemeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatalogTheme(
      controller: _controller,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _controller,
        builder: (context, mode, _) {
          return MaterialApp(
            title: widget.title,
            theme: widget.lightTheme ?? ThemeData.light(useMaterial3: true),
            darkTheme: widget.darkTheme ?? ThemeData.dark(useMaterial3: true),
            themeMode: mode,
            home: _PlaceholderHome(entries: widget.entries),
          );
        },
      ),
    );
  }
}

// Replaced by GridScreen in Task 5.
class _PlaceholderHome extends StatelessWidget {
  final List<CatalogEntry> entries;
  const _PlaceholderHome({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Library')),
      body: Center(child: Text('Entries: ${entries.length}')),
    );
  }
}
```

- [ ] **Step 4: Update the barrel export**

Edit: `lib/widget_library.dart`
```dart
library widget_library;

export 'src/catalog_app.dart';
export 'src/models/catalog_entry.dart';
```

- [ ] **Step 5: Run tests + analyze**

Run:
```bash
flutter test
flutter analyze
```
Expected: all tests pass, no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add lib/src/catalog_app.dart lib/widget_library.dart test/catalog_app_test.dart
git commit -m "feat: add CatalogApp root widget with theme wiring"
```

---

### Task 5: `GridScreen`

**Goal:** Home screen shown by `CatalogApp`: searchable 2-column grid of entries; tapping a tile pushes `DetailScreen` (stubbed for now).

**Files:**
- Create: `lib/src/screens/grid_screen.dart`
- Modify: `lib/src/catalog_app.dart` (replace `_PlaceholderHome` with `GridScreen`)
- Test: `test/grid_screen_test.dart`

**Acceptance Criteria:**
- [ ] Empty entries list shows a centered "No widgets registered" message
- [ ] Non-empty list renders one tile per entry with the entry's name visible
- [ ] Tile uses `entry.thumbnail` when provided; otherwise renders `entry.states.values.first` inside a `FittedBox`
- [ ] Tapping the search icon reveals a `TextField` in the app bar; typing filters tiles by case-insensitive substring on `name`
- [ ] Tapping the theme icon toggles `CatalogTheme.of(context)`
- [ ] Tapping a tile pushes a route whose widget is `DetailScreen` (it may not be fully implemented yet — use a thin stub if needed)

**Verify:** `flutter test test/grid_screen_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Add a minimal `DetailScreen` stub so `GridScreen` can navigate**

File: `lib/src/screens/detail_screen.dart`
```dart
import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';

class DetailScreen extends StatelessWidget {
  final CatalogEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: const SizedBox.shrink(),
    );
  }
}
```
(Task 6 replaces the body.)

- [ ] **Step 2: Write the failing test**

File: `test/grid_screen_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/screens/detail_screen.dart';

CatalogEntry _entry(String name) => CatalogEntry(
      name: name,
      states: {'default': (_) => Text('preview:$name')},
    );

void main() {
  testWidgets('shows empty state when entries list is empty', (tester) async {
    await tester.pumpWidget(const CatalogApp(entries: []));
    expect(find.text('No widgets registered'), findsOneWidget);
  });

  testWidgets('renders one tile per entry with name visible', (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button'), _entry('Card')]),
    );
    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
  });

  testWidgets('search filters tiles by case-insensitive substring',
      (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button'), _entry('Card')]),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'but');
    await tester.pump();

    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsNothing);
  });

  testWidgets('tapping tile pushes DetailScreen', (tester) async {
    await tester.pumpWidget(CatalogApp(entries: [_entry('Button')]));
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('theme toggle flips MaterialApp.themeMode', (tester) async {
    await tester.pumpWidget(CatalogApp(entries: [_entry('Button')]));
    final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(before, ThemeMode.light);

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(after, ThemeMode.dark);
  });
}
```

- [ ] **Step 3: Run test to see it fail**

Run: `flutter test test/grid_screen_test.dart`
Expected: FAIL — `GridScreen` not hooked up; placeholder home has no tiles.

- [ ] **Step 4: Implement `GridScreen`**

File: `lib/src/screens/grid_screen.dart`
```dart
import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import 'detail_screen.dart';

class GridScreen extends StatefulWidget {
  final List<CatalogEntry> entries;
  final String title;
  const GridScreen({super.key, required this.entries, required this.title});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  bool _searching = false;
  String _query = '';

  List<CatalogEntry> get _filtered {
    if (_query.isEmpty) return widget.entries;
    final q = _query.toLowerCase();
    return widget.entries.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CatalogTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search widgets',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              theme.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: theme.toggle,
          ),
        ],
      ),
      body: widget.entries.isEmpty
          ? const Center(child: Text('No widgets registered'))
          : _GridBody(entries: _filtered),
    );
  }
}

class _GridBody extends StatelessWidget {
  final List<CatalogEntry> entries;
  const _GridBody({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) => _Tile(entry: entries[i]),
    );
  }
}

class _Tile extends StatelessWidget {
  final CatalogEntry entry;
  const _Tile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final preview = entry.thumbnail ??
        FittedBox(
          fit: BoxFit.contain,
          child: Builder(builder: entry.states.values.first),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(child: preview),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Replace `_PlaceholderHome` in `CatalogApp`**

Edit: `lib/src/catalog_app.dart` — remove `_PlaceholderHome` class and change the `home:` line:
```dart
home: GridScreen(entries: widget.entries, title: widget.title),
```
Add import at top:
```dart
import 'screens/grid_screen.dart';
```

- [ ] **Step 6: Run tests + analyze**

Run:
```bash
flutter test
flutter analyze
```
Expected: all tests pass, no analyzer issues.

- [ ] **Step 7: Commit**

```bash
git add lib/src/screens/grid_screen.dart lib/src/screens/detail_screen.dart lib/src/catalog_app.dart test/grid_screen_test.dart
git commit -m "feat: add GridScreen with search and theme toggle"
```

---

### Task 6: `DetailScreen` with chip state selector

**Goal:** Replace stub `DetailScreen` body with chip strip + live preview wrapped in `ErrorBoundary`.

**Files:**
- Modify: `lib/src/screens/detail_screen.dart`
- Test: `test/detail_screen_test.dart`

**Acceptance Criteria:**
- [ ] Renders one `ChoiceChip` per state key; first key is selected initially
- [ ] Body renders the currently selected state's builder
- [ ] Tapping a different chip swaps the rendered preview
- [ ] A builder that throws is handled by `ErrorBoundary` and shows its error text
- [ ] Theme toggle icon in app bar flips `CatalogTheme` controller

**Verify:** `flutter test test/detail_screen_test.dart` → all green.

**Steps:**

- [ ] **Step 1: Write the failing test**

File: `test/detail_screen_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/screens/detail_screen.dart';

Widget _host(CatalogEntry entry) => CatalogApp(entries: [entry]);

Future<void> _openDetail(WidgetTester tester, CatalogEntry entry) async {
  await tester.pumpWidget(_host(entry));
  await tester.tap(find.text(entry.name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders first state initially', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
      'disabled': (_) => const Text('STATE-disabled'),
    });
    await _openDetail(tester, entry);
    expect(find.text('STATE-default'), findsOneWidget);
    expect(find.text('STATE-disabled'), findsNothing);
  });

  testWidgets('tapping a chip swaps the rendered preview', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
      'disabled': (_) => const Text('STATE-disabled'),
    });
    await _openDetail(tester, entry);

    await tester.tap(find.widgetWithText(ChoiceChip, 'disabled'));
    await tester.pumpAndSettle();

    expect(find.text('STATE-disabled'), findsOneWidget);
    expect(find.text('STATE-default'), findsNothing);
  });

  testWidgets('throwing builder is caught by ErrorBoundary', (tester) async {
    final entry = CatalogEntry(name: 'Bad', states: {
      'default': (_) => throw StateError('kaboom'),
    });
    await _openDetail(tester, entry);
    expect(find.textContaining('kaboom'), findsOneWidget);
  });

  testWidgets('theme toggle in detail app bar flips theme mode', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
    });
    await _openDetail(tester, entry);

    final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(before, ThemeMode.light);

    await tester.tap(find.descendant(
      of: find.byType(DetailScreen),
      matching: find.byTooltip('Toggle theme'),
    ));
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(after, ThemeMode.dark);
  });
}
```

- [ ] **Step 2: Run test to see it fail**

Run: `flutter test test/detail_screen_test.dart`
Expected: FAIL — `DetailScreen` body is empty, no chips.

- [ ] **Step 3: Implement the real `DetailScreen`**

File: `lib/src/screens/detail_screen.dart` (full replacement)
```dart
import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/error_boundary.dart';

class DetailScreen extends StatefulWidget {
  final CatalogEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _selected = widget.entry.states.keys.first;

  @override
  Widget build(BuildContext context) {
    final theme = CatalogTheme.of(context);
    final builder = widget.entry.states[_selected]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              theme.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: theme.toggle,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final key in widget.entry.states.keys)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(key),
                      selected: _selected == key,
                      onSelected: (_) => setState(() => _selected = key),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorBoundary(
                  key: ValueKey(_selected),
                  builder: builder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests + analyze**

Run:
```bash
flutter test
flutter analyze
```
Expected: all tests pass, no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/src/screens/detail_screen.dart test/detail_screen_test.dart
git commit -m "feat: add DetailScreen with chip state selector and error boundary"
```

---

### Task 7: Example app wiring + smoke run

**Goal:** Populate `example/` with a working catalog using a real sample widget, and run it on a connected device/emulator to confirm end-to-end behavior.

**Files:**
- Create: `example/lib/catalog.dart`
- Create: `example/lib/widgets/primary_button.dart`
- Modify: `example/lib/main.dart`

**Acceptance Criteria:**
- [ ] `example/` compiles and boots on Android emulator (`flutter run -d <android-device>` from `example/`)
- [ ] Home grid shows at least 2 entries with visible previews
- [ ] Tapping an entry navigates to detail; chip changes swap preview
- [ ] Theme toggle works on both screens
- [ ] Search filters grid correctly

**Verify:** Manual smoke run documented below — golden path + 2 edge cases.

**Steps:**

- [ ] **Step 1: Create a sample widget**

File: `example/lib/widgets/primary_button.dart`
```dart
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled && !loading ? () {} : null,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
```

- [ ] **Step 2: Create the catalog list**

File: `example/lib/catalog.dart`
```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'widgets/primary_button.dart';

List<CatalogEntry> buildCatalog() => [
      CatalogEntry(
        name: 'Primary Button',
        states: {
          'default': (_) => const PrimaryButton(label: 'Tap me'),
          'disabled': (_) => const PrimaryButton(label: 'Tap me', enabled: false),
          'loading': (_) => const PrimaryButton(label: 'Tap me', loading: true),
        },
      ),
      CatalogEntry(
        name: 'Chip',
        states: {
          'default': (_) => const Chip(label: Text('Tag')),
          'with-avatar': (_) => const Chip(
                avatar: CircleAvatar(child: Text('A')),
                label: Text('Tag'),
              ),
        },
      ),
    ];
```

- [ ] **Step 3: Wire `main.dart` to use `CatalogApp`**

File: `example/lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'catalog.dart';

void main() {
  runApp(CatalogApp(
    entries: buildCatalog(),
    lightTheme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
  ));
}
```

- [ ] **Step 4: Analyze**

Run:
```bash
cd example && flutter analyze && cd ..
```
Expected: `No issues found!`

- [ ] **Step 5: Smoke run on Android**

Run from `example/`:
```bash
flutter run -d <your-android-device-id>
```
Manually verify:
1. Grid shows 2 tiles: "Primary Button" and "Chip"
2. Tap "Primary Button" → chips: `default`, `disabled`, `loading`. Tapping each changes preview.
3. Theme icon flips to dark; previews remain correct.
4. Back to grid. Tap search, type `chip` — only Chip tile remains. Clear.
5. Tap the search close icon — all tiles return.

- [ ] **Step 6: Commit**

```bash
git add example/
git commit -m "feat(example): wire sample catalog entries and smoke test"
```

- [ ] **Step 7: Push**

```bash
git push
```
