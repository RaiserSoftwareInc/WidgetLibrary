# Live Knobs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a live, reactive knob system to `widget_library` so catalog entries can expose typed controls (sliders, toggles, dropdowns, text, color, enum) that rebuild the preview in real time, with hot-reload-safe entry registration.

**Architecture:** Additive `CatalogEntry.live(...)` constructor declares `List<Knob>` + `Widget Function(BuildContext, KnobValues) builder`. A single `KnobController` (`ChangeNotifier` over `Map<String, Object?>`) drives a `ListenableBuilder` around the preview. Entries are passed to `CatalogApp` as a builder function (`List<CatalogEntry> Function()`) invoked inside `build()` so hot reload picks up default-value edits. `DetailScreen` branches: legacy `states`-map path is unchanged; live path renders an inline split with the knob panel below the preview.

**Tech Stack:** Dart 3 sealed classes, Flutter Material 3, `ChangeNotifier`/`ListenableBuilder`, `flutter_test`.

Source spec: `docs/superpowers/specs/2026-04-23-live-knobs-design.md`.

---

## File Structure

**New files:**

- `lib/src/knobs/knob.dart` — sealed `Knob<T>` base + 6 typed subclasses.
- `lib/src/knobs/knob_controller.dart` — `ChangeNotifier` owning `Map<String, Object?>`, with `reconcile`/`reset`/`resetAll`/`set`.
- `lib/src/knobs/knob_values.dart` — read-only typed accessor.
- `lib/src/widgets/knob_panel.dart` — panel root (`ListView` of rows, header with Reset-all).
- `lib/src/widgets/knob_rows/double_row.dart`
- `lib/src/widgets/knob_rows/int_row.dart`
- `lib/src/widgets/knob_rows/bool_row.dart`
- `lib/src/widgets/knob_rows/string_row.dart`
- `lib/src/widgets/knob_rows/enum_row.dart`
- `lib/src/widgets/knob_rows/color_row.dart`
- `test/knobs/knob_controller_test.dart`
- `test/knobs/knob_values_test.dart`
- `test/models/catalog_entry_live_test.dart`
- `test/widgets/knob_panel_test.dart`
- `test/screens/detail_screen_live_test.dart`

**Modified:**

- `lib/src/models/catalog_entry.dart` — add `.live` named ctor + `List<Knob>? knobs` + `Widget Function(BuildContext, KnobValues)? builder`.
- `lib/src/catalog_app.dart` — `entries` param becomes `List<CatalogEntry> Function()`.
- `lib/src/screens/grid_screen.dart` — accept builder fn; invoke in `build`; `_Tile` renders `.live` preview via builder + default-seeded ephemeral `KnobValues`.
- `lib/src/screens/detail_screen.dart` — take `CatalogEntry Function()`; `reassemble` hook; knob layout branch; `ListenableBuilder` around preview.
- `lib/widget_library.dart` — export knob types + `KnobValues`.
- `example/lib/catalog.dart` — migrate Primary Button to `.live`.
- `example/lib/main.dart` — pass `entries: buildCatalog` (drop parens).

---

## Task 1: Knob Types + KnobValues

**Goal:** Define the sealed `Knob<T>` hierarchy, the six typed subclasses, and the `KnobValues` typed accessor. No behavior yet — just types and pure getters.

**Files:**
- Create: `lib/src/knobs/knob.dart`
- Create: `lib/src/knobs/knob_values.dart`
- Create: `test/knobs/knob_values_test.dart`

**Acceptance Criteria:**
- [ ] `Knob<T>` is a sealed class with `id`, `label`, `defaultValue` and a `const` constructor.
- [ ] `DoubleKnob`, `IntKnob`, `BoolKnob`, `StringKnob`, `EnumKnob<T>`, `ColorKnob` all extend `Knob<T>` and expose their type-specific fields as `final`.
- [ ] `KnobValues` wraps a `Map<String, Object?>` and offers type-specific getters: `getDouble`, `getInt`, `getBool`, `getString`, `getColor`, `getEnum<T>`, plus `valueOf<T>(Knob<T>)`.
- [ ] `KnobValues` throws `StateError` when a missing id is requested (clearer than a generic cast error).

**Verify:** `flutter test test/knobs/knob_values_test.dart` → all pass.

**Steps:**

- [ ] **Step 1: Write `lib/src/knobs/knob.dart`**

```dart
import 'package:flutter/painting.dart';

sealed class Knob<T> {
  final String id;
  final String label;
  final T defaultValue;

  const Knob({
    required this.id,
    required this.label,
    required this.defaultValue,
  });
}

class DoubleKnob extends Knob<double> {
  final double min;
  final double max;
  final double? step;

  const DoubleKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.min,
    required this.max,
    this.step,
  })  : assert(min < max, 'DoubleKnob.min must be < max'),
        assert(
          defaultValue >= min && defaultValue <= max,
          'DoubleKnob.defaultValue must be within [min, max]',
        );
}

class IntKnob extends Knob<int> {
  final int min;
  final int max;
  final int step;

  const IntKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.min,
    required this.max,
    this.step = 1,
  })  : assert(min < max, 'IntKnob.min must be < max'),
        assert(step > 0, 'IntKnob.step must be > 0'),
        assert(
          defaultValue >= min && defaultValue <= max,
          'IntKnob.defaultValue must be within [min, max]',
        );
}

class BoolKnob extends Knob<bool> {
  const BoolKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
  });
}

class StringKnob extends Knob<String> {
  final String? hint;

  const StringKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    this.hint,
  });
}

class EnumKnob<T> extends Knob<T> {
  final List<T> values;
  final String Function(T value)? labelOf;

  const EnumKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.values,
    this.labelOf,
  }) : assert(values.length > 0, 'EnumKnob.values must not be empty');
}

class ColorKnob extends Knob<Color> {
  final List<Color>? swatches;

  const ColorKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    this.swatches,
  });
}
```

- [ ] **Step 2: Write `lib/src/knobs/knob_values.dart`**

```dart
import 'package:flutter/painting.dart';

import 'knob.dart';

class KnobValues {
  final Map<String, Object?> _values;

  const KnobValues(this._values);

  Object? _raw(String id) {
    if (!_values.containsKey(id)) {
      throw StateError('KnobValues: no value for id "$id"');
    }
    return _values[id];
  }

  double getDouble(String id) => _raw(id) as double;
  int getInt(String id) => _raw(id) as int;
  bool getBool(String id) => _raw(id) as bool;
  String getString(String id) => _raw(id) as String;
  Color getColor(String id) => _raw(id) as Color;
  T getEnum<T>(String id) => _raw(id) as T;

  T valueOf<T>(Knob<T> knob) => _raw(knob.id) as T;
}
```

- [ ] **Step 3: Write `test/knobs/knob_values_test.dart`**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_values.dart';

void main() {
  group('KnobValues', () {
    test('typed getters return correctly typed values', () {
      final values = KnobValues({
        'height': 220.0,
        'count': 3,
        'enabled': true,
        'label': 'Tap me',
        'bg': const Color(0xFF112233),
        'mode': 'dark',
      });

      expect(values.getDouble('height'), 220.0);
      expect(values.getInt('count'), 3);
      expect(values.getBool('enabled'), true);
      expect(values.getString('label'), 'Tap me');
      expect(values.getColor('bg'), const Color(0xFF112233));
      expect(values.getEnum<String>('mode'), 'dark');
    });

    test('valueOf reads by knob instance', () {
      const knob = DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 100,
        min: 0,
        max: 200,
      );
      final values = KnobValues({'h': 150.0});

      expect(values.valueOf(knob), 150.0);
    });

    test('missing id throws StateError', () {
      final values = KnobValues({});
      expect(() => values.getDouble('missing'), throwsStateError);
    });

    test('asserts on invalid DoubleKnob range', () {
      expect(
        () => DoubleKnob(
          id: 'x',
          label: 'X',
          defaultValue: 500,
          min: 0,
          max: 100,
        ),
        throwsAssertionError,
      );
    });
  });
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/knobs/knob_values_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/knobs/knob.dart lib/src/knobs/knob_values.dart test/knobs/knob_values_test.dart
git commit -m "feat(knobs): add Knob type hierarchy and KnobValues accessor"
```

---

## Task 2: KnobController

**Goal:** A `ChangeNotifier` that owns knob values as `Map<String, Object?>`, seeds defaults on construction, supports per-id `set`/`reset`, `resetAll`, and `reconcile(List<Knob>)` that preserves matching-id user values on hot reload.

**Files:**
- Create: `lib/src/knobs/knob_controller.dart`
- Create: `test/knobs/knob_controller_test.dart`

**Acceptance Criteria:**
- [ ] Constructing with a knob list seeds defaults.
- [ ] `set` notifies listeners; `reset` writes back the default for that id.
- [ ] `resetAll` writes defaults for every current knob.
- [ ] `reconcile(next)` drops ids absent from `next`, adds new ids with defaults, and preserves existing values for ids present in both — even when the default has changed.
- [ ] `reconcile` throws `StateError` if `next` contains a knob with an id whose value in the existing map is of an incompatible runtime type (protects against id-reuse across types).
- [ ] `KnobValues(controller.values)` returns current values.

**Verify:** `flutter test test/knobs/knob_controller_test.dart` → all pass.

**Steps:**

- [ ] **Step 1: Write `lib/src/knobs/knob_controller.dart`**

```dart
import 'package:flutter/foundation.dart';

import 'knob.dart';
import 'knob_values.dart';

class KnobController extends ChangeNotifier {
  final Map<String, Object?> _values = {};
  List<Knob> _knobs;

  KnobController(List<Knob> knobs) : _knobs = List.unmodifiable(knobs) {
    for (final k in _knobs) {
      _values[k.id] = k.defaultValue;
    }
  }

  List<Knob> get knobs => _knobs;
  Map<String, Object?> get values => Map.unmodifiable(_values);
  KnobValues get readOnly => KnobValues(_values);

  void set(String id, Object? value) {
    if (!_values.containsKey(id)) {
      throw StateError('KnobController: unknown knob id "$id"');
    }
    _values[id] = value;
    notifyListeners();
  }

  void reset(String id) {
    final knob = _knobs.firstWhere(
      (k) => k.id == id,
      orElse: () => throw StateError('KnobController: unknown knob id "$id"'),
    );
    _values[id] = knob.defaultValue;
    notifyListeners();
  }

  void resetAll() {
    for (final k in _knobs) {
      _values[k.id] = k.defaultValue;
    }
    notifyListeners();
  }

  void reconcile(List<Knob> next) {
    final nextById = {for (final k in next) k.id: k};

    // Type-compat guard.
    for (final k in next) {
      final existing = _values[k.id];
      if (existing != null && !_isCompatible(k, existing)) {
        throw StateError(
          'KnobController.reconcile: id "${k.id}" changed type; '
          'existing value $existing is incompatible with ${k.runtimeType}',
        );
      }
    }

    // Drop removed.
    _values.removeWhere((id, _) => !nextById.containsKey(id));

    // Seed new.
    for (final k in next) {
      if (!_values.containsKey(k.id)) {
        _values[k.id] = k.defaultValue;
      }
    }

    _knobs = List.unmodifiable(next);
    notifyListeners();
  }

  static bool _isCompatible(Knob knob, Object value) {
    return switch (knob) {
      DoubleKnob() => value is double,
      IntKnob() => value is int,
      BoolKnob() => value is bool,
      StringKnob() => value is String,
      ColorKnob() => value is Object, // Color check deferred to painting import;
      EnumKnob(values: final opts) => opts.contains(value),
    };
  }
}
```

- [ ] **Step 2: Write `test/knobs/knob_controller_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';

void main() {
  group('KnobController', () {
    const height = DoubleKnob(
      id: 'height',
      label: 'Height',
      defaultValue: 220,
      min: 100,
      max: 400,
    );
    const enabled = BoolKnob(
      id: 'enabled',
      label: 'Enabled',
      defaultValue: true,
    );

    test('seeds defaults on construction', () {
      final c = KnobController([height, enabled]);
      expect(c.values['height'], 220.0);
      expect(c.values['enabled'], true);
    });

    test('set writes value and notifies', () {
      final c = KnobController([height]);
      var n = 0;
      c.addListener(() => n++);
      c.set('height', 300.0);
      expect(c.values['height'], 300.0);
      expect(n, 1);
    });

    test('reset restores default', () {
      final c = KnobController([height]);
      c.set('height', 300.0);
      c.reset('height');
      expect(c.values['height'], 220.0);
    });

    test('resetAll restores every default', () {
      final c = KnobController([height, enabled]);
      c.set('height', 300.0);
      c.set('enabled', false);
      c.resetAll();
      expect(c.values['height'], 220.0);
      expect(c.values['enabled'], true);
    });

    test('set on unknown id throws StateError', () {
      final c = KnobController([height]);
      expect(() => c.set('ghost', 1), throwsStateError);
    });

    test('reconcile preserves matching-id user value', () {
      final c = KnobController([height]);
      c.set('height', 320.0);

      const heightUpdatedDefault = DoubleKnob(
        id: 'height',
        label: 'Height',
        defaultValue: 260, // changed default
        min: 100,
        max: 400,
      );
      c.reconcile([heightUpdatedDefault]);

      expect(c.values['height'], 320.0); // user value kept
    });

    test('reconcile drops removed ids and seeds new ones', () {
      final c = KnobController([height]);
      c.set('height', 300.0);
      c.reconcile([enabled]);

      expect(c.values.containsKey('height'), false);
      expect(c.values['enabled'], true);
    });

    test('reconcile rejects id reuse across incompatible types', () {
      final c = KnobController([height]);
      const stringHeight = StringKnob(
        id: 'height',
        label: 'Height',
        defaultValue: 'tall',
      );
      expect(() => c.reconcile([stringHeight]), throwsStateError);
    });
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/knobs/knob_controller_test.dart`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/knobs/knob_controller.dart test/knobs/knob_controller_test.dart
git commit -m "feat(knobs): add KnobController with reconcile for hot-reload safety"
```

---

## Task 3: CatalogEntry.live

**Goal:** Add a `.live` named constructor to `CatalogEntry` that stores a typed knob list and a builder closure. The legacy `CatalogEntry(name:, states:, ...)` constructor stays identical.

**Files:**
- Modify: `lib/src/models/catalog_entry.dart`
- Create: `test/models/catalog_entry_live_test.dart`

**Acceptance Criteria:**
- [ ] `CatalogEntry.live({required name, required knobs, required builder, ...})` compiles.
- [ ] `entry.knobs` returns the passed list for `.live`, `null` for legacy.
- [ ] `entry.builder` returns the passed closure for `.live`, `null` for legacy.
- [ ] `.live` synthesizes a single `states` entry keyed `'live'` that invokes `builder` with the default `KnobValues` (enables `_Tile` thumbnail fallback in the grid without branching).
- [ ] Existing `catalog_entry_test.dart` still passes.

**Verify:**
`flutter test test/catalog_entry_test.dart test/models/catalog_entry_live_test.dart` → all pass.

**Steps:**

- [ ] **Step 1: Edit `lib/src/models/catalog_entry.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../knobs/knob.dart';
import '../knobs/knob_values.dart';

@immutable
class CatalogEntry {
  final String name;
  final String? category;
  final Map<String, WidgetBuilder> states;
  final Widget? thumbnail;

  /// Virtual viewport given to the widget when rendered in the viewer. Any
  /// `double.infinity`, `Stack(fit: expand)`, or fill-width/height pattern
  /// resolves against these bounds instead of the screen or an infinite
  /// canvas. Defaults to a phone-like 390x844. Override per-entry for
  /// widgets with a different natural footprint.
  final Size previewSize;

  /// Live-mode knob declarations. `null` for legacy `states`-based entries.
  final List<Knob>? knobs;

  /// Live-mode builder. `null` for legacy entries.
  final Widget Function(BuildContext context, KnobValues values)? builder;

  CatalogEntry({
    required this.name,
    required Map<String, WidgetBuilder> states,
    this.category,
    this.thumbnail,
    this.previewSize = const Size(390, 844),
  })  : assert(states.isNotEmpty, 'CatalogEntry.states must not be empty'),
        states = Map.unmodifiable(states),
        knobs = null,
        builder = null;

  CatalogEntry.live({
    required this.name,
    required List<Knob> knobs,
    required Widget Function(BuildContext, KnobValues) builder,
    this.category,
    this.thumbnail,
    this.previewSize = const Size(390, 844),
  })  : assert(knobs.isNotEmpty, 'CatalogEntry.live: knobs must not be empty'),
        knobs = List.unmodifiable(knobs),
        builder = builder,
        states = Map.unmodifiable({
          'live': (ctx) => builder(
                ctx,
                KnobValues({for (final k in knobs) k.id: k.defaultValue}),
              ),
        });

  bool get isLive => knobs != null && builder != null;
}
```

- [ ] **Step 2: Write `test/models/catalog_entry_live_test.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';

void main() {
  group('CatalogEntry.live', () {
    test('stores knobs and builder; isLive is true', () {
      final entry = CatalogEntry.live(
        name: 'Header',
        knobs: const [
          DoubleKnob(
            id: 'h',
            label: 'Height',
            defaultValue: 220,
            min: 100,
            max: 400,
          ),
        ],
        builder: (ctx, v) => SizedBox(height: v.getDouble('h')),
      );

      expect(entry.isLive, true);
      expect(entry.knobs, isNotNull);
      expect(entry.knobs!.first.id, 'h');
      expect(entry.builder, isNotNull);
    });

    test('synthesizes single default state keyed "live"', () {
      final entry = CatalogEntry.live(
        name: 'Header',
        knobs: const [
          DoubleKnob(
            id: 'h',
            label: 'Height',
            defaultValue: 220,
            min: 100,
            max: 400,
          ),
        ],
        builder: (ctx, v) => SizedBox(height: v.getDouble('h')),
      );

      expect(entry.states.keys.toList(), ['live']);
    });

    test('legacy constructor still has null knobs and builder', () {
      final entry = CatalogEntry(
        name: 'Button',
        states: {'default': (_) => const SizedBox()},
      );

      expect(entry.isLive, false);
      expect(entry.knobs, isNull);
      expect(entry.builder, isNull);
    });

    test('asserts when knobs is empty', () {
      expect(
        () => CatalogEntry.live(
          name: 'Bad',
          knobs: const [],
          builder: (_, __) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/catalog_entry_test.dart test/models/catalog_entry_live_test.dart`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/models/catalog_entry.dart test/models/catalog_entry_live_test.dart
git commit -m "feat(catalog): add CatalogEntry.live constructor for knob-driven entries"
```

---

## Task 4: Knob Row Widgets

**Goal:** Create one widget per knob type, each reading from `KnobController`, writing through `set`, and exposing `wl.detail.knob.<id>.*` value keys for Marionette. Stateless except where the row owns transient UI state (e.g. text field controller).

**Files:**
- Create: `lib/src/widgets/knob_rows/double_row.dart`
- Create: `lib/src/widgets/knob_rows/int_row.dart`
- Create: `lib/src/widgets/knob_rows/bool_row.dart`
- Create: `lib/src/widgets/knob_rows/string_row.dart`
- Create: `lib/src/widgets/knob_rows/enum_row.dart`
- Create: `lib/src/widgets/knob_rows/color_row.dart`

**Acceptance Criteria:**
- [ ] Each row accepts its concrete knob type + a `KnobController` and reads its live value.
- [ ] Each row writes through `controller.set(id, value)` on user change.
- [ ] Each row exposes keys `wl.detail.knob.<id>`, `wl.detail.knob.<id>.control`, `wl.detail.knob.<id>.value`, `wl.detail.knob.<id>.reset`.
- [ ] No `const` on any builder-returned widget that depends on `knob` or `controller` (prevents stale paint under hot reload).

**Verify:** `flutter analyze lib/src/widgets/knob_rows/` → no errors.

**Steps:**

- [ ] **Step 1: Write `lib/src/widgets/knob_rows/double_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class DoubleRow extends StatelessWidget {
  final DoubleKnob knob;
  final KnobController controller;

  const DoubleRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = (controller.values[knob.id] as double);
    final divisions = knob.step != null
        ? ((knob.max - knob.min) / knob.step!).round()
        : null;

    return Padding(
      key: ValueKey('wl.detail.knob.${knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(knob.label)),
              Text(
                value.toStringAsFixed(1),
                key: ValueKey('wl.detail.knob.${knob.id}.value'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                key: ValueKey('wl.detail.knob.${knob.id}.reset'),
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt, size: 18),
                onPressed: () => controller.reset(knob.id),
              ),
            ],
          ),
          Slider(
            key: ValueKey('wl.detail.knob.${knob.id}.control'),
            min: knob.min,
            max: knob.max,
            divisions: divisions,
            value: value.clamp(knob.min, knob.max),
            onChanged: (v) => controller.set(knob.id, v),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `lib/src/widgets/knob_rows/int_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class IntRow extends StatelessWidget {
  final IntKnob knob;
  final KnobController controller;

  const IntRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id] as int;
    final divisions = ((knob.max - knob.min) / knob.step).round();

    return Padding(
      key: ValueKey('wl.detail.knob.${knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(knob.label)),
              Text(
                '$value',
                key: ValueKey('wl.detail.knob.${knob.id}.value'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                key: ValueKey('wl.detail.knob.${knob.id}.reset'),
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt, size: 18),
                onPressed: () => controller.reset(knob.id),
              ),
            ],
          ),
          Slider(
            key: ValueKey('wl.detail.knob.${knob.id}.control'),
            min: knob.min.toDouble(),
            max: knob.max.toDouble(),
            divisions: divisions,
            value: value.toDouble().clamp(
                  knob.min.toDouble(),
                  knob.max.toDouble(),
                ),
            onChanged: (v) => controller.set(knob.id, v.round()),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Write `lib/src/widgets/knob_rows/bool_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class BoolRow extends StatelessWidget {
  final BoolKnob knob;
  final KnobController controller;

  const BoolRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id] as bool;

    return Padding(
      key: ValueKey('wl.detail.knob.${knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(child: Text(knob.label)),
          Text(
            value ? 'on' : 'off',
            key: ValueKey('wl.detail.knob.${knob.id}.value'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Switch(
            key: ValueKey('wl.detail.knob.${knob.id}.control'),
            value: value,
            onChanged: (v) => controller.set(knob.id, v),
          ),
          IconButton(
            key: ValueKey('wl.detail.knob.${knob.id}.reset'),
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: () => controller.reset(knob.id),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Write `lib/src/widgets/knob_rows/string_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class StringRow extends StatefulWidget {
  final StringKnob knob;
  final KnobController controller;

  const StringRow({super.key, required this.knob, required this.controller});

  @override
  State<StringRow> createState() => _StringRowState();
}

class _StringRowState extends State<StringRow> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.values[widget.knob.id] as String,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('wl.detail.knob.${widget.knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(widget.knob.label)),
          Expanded(
            child: TextField(
              key: ValueKey('wl.detail.knob.${widget.knob.id}.control'),
              controller: _text,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.knob.hint,
              ),
              onChanged: (v) => widget.controller.set(widget.knob.id, v),
            ),
          ),
          IconButton(
            key: ValueKey('wl.detail.knob.${widget.knob.id}.reset'),
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: () {
              widget.controller.reset(widget.knob.id);
              _text.text = widget.knob.defaultValue;
            },
          ),
          // Readback mirror for Marionette.
          Offstage(
            child: Text(
              _text.text,
              key: ValueKey('wl.detail.knob.${widget.knob.id}.value'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Write `lib/src/widgets/knob_rows/enum_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class EnumRow<T> extends StatelessWidget {
  final EnumKnob<T> knob;
  final KnobController controller;

  const EnumRow({super.key, required this.knob, required this.controller});

  String _label(T v) => knob.labelOf?.call(v) ?? '$v';

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id] as T;

    return Padding(
      key: ValueKey('wl.detail.knob.${knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Expanded(child: Text(knob.label)),
          DropdownButton<T>(
            key: ValueKey('wl.detail.knob.${knob.id}.control'),
            value: value,
            items: [
              for (final v in knob.values)
                DropdownMenuItem<T>(value: v, child: Text(_label(v))),
            ],
            onChanged: (v) {
              if (v != null) controller.set(knob.id, v);
            },
          ),
          Offstage(
            child: Text(
              _label(value),
              key: ValueKey('wl.detail.knob.${knob.id}.value'),
            ),
          ),
          IconButton(
            key: ValueKey('wl.detail.knob.${knob.id}.reset'),
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: () => controller.reset(knob.id),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Write `lib/src/widgets/knob_rows/color_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class ColorRow extends StatelessWidget {
  final ColorKnob knob;
  final KnobController controller;

  const ColorRow({super.key, required this.knob, required this.controller});

  static const _defaultSwatches = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id] as Color;
    final swatches = knob.swatches ?? _defaultSwatches;

    return Padding(
      key: ValueKey('wl.detail.knob.${knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(knob.label)),
              Text(
                '#${value.value.toRadixString(16).padLeft(8, '0')}',
                key: ValueKey('wl.detail.knob.${knob.id}.value'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                key: ValueKey('wl.detail.knob.${knob.id}.reset'),
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt, size: 18),
                onPressed: () => controller.reset(knob.id),
              ),
            ],
          ),
          SizedBox(
            height: 32,
            child: ListView.separated(
              key: ValueKey('wl.detail.knob.${knob.id}.control'),
              scrollDirection: Axis.horizontal,
              itemCount: swatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final c = swatches[i];
                final selected = c.value == value.value;
                return GestureDetector(
                  key: ValueKey(
                    'wl.detail.knob.${knob.id}.swatch.'
                    '${c.value.toRadixString(16)}',
                  ),
                  onTap: () => controller.set(knob.id, c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run analyzer**

Run: `flutter analyze lib/src/widgets/knob_rows/`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/src/widgets/knob_rows/
git commit -m "feat(knobs): add per-type knob row widgets with Marionette keys"
```

---

## Task 5: KnobPanel

**Goal:** The panel root assembles rows by dispatching on knob runtime type, renders a header with a global "Reset all" action, and wraps everything in a `ListenableBuilder` so value changes trigger re-render. Keyed `wl.detail.knob_panel`.

**Files:**
- Create: `lib/src/widgets/knob_panel.dart`
- Create: `test/widgets/knob_panel_test.dart`

**Acceptance Criteria:**
- [ ] Given a `KnobController` with mixed knob types, panel renders one row per knob in declaration order.
- [ ] Panel re-renders on `controller.set(...)` (the readback label text updates).
- [ ] Global "Reset all" button is keyed `wl.detail.knobs.reset_all` and calls `controller.resetAll()`.
- [ ] Unknown knob subclass throws `UnimplementedError` (guards future additions).

**Verify:** `flutter test test/widgets/knob_panel_test.dart` → all pass.

**Steps:**

- [ ] **Step 1: Write `lib/src/widgets/knob_panel.dart`**

```dart
import 'package:flutter/material.dart';

import '../knobs/knob.dart';
import '../knobs/knob_controller.dart';
import 'knob_rows/bool_row.dart';
import 'knob_rows/color_row.dart';
import 'knob_rows/double_row.dart';
import 'knob_rows/enum_row.dart';
import 'knob_rows/int_row.dart';
import 'knob_rows/string_row.dart';

class KnobPanel extends StatelessWidget {
  final KnobController controller;

  const KnobPanel({super.key, required this.controller});

  Widget _rowFor(Knob knob) {
    return switch (knob) {
      DoubleKnob() => DoubleRow(knob: knob, controller: controller),
      IntKnob() => IntRow(knob: knob, controller: controller),
      BoolKnob() => BoolRow(knob: knob, controller: controller),
      StringKnob() => StringRow(knob: knob, controller: controller),
      ColorKnob() => ColorRow(knob: knob, controller: controller),
      EnumKnob<dynamic>() => EnumRow<dynamic>(
          knob: knob,
          controller: controller,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final knobs = controller.knobs;
        return Material(
          key: const ValueKey('wl.detail.knob_panel'),
          color: cs.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Knobs',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      key: const ValueKey('wl.detail.knobs.reset_all'),
                      onPressed: controller.resetAll,
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset all'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: knobs.length,
                  itemBuilder: (ctx, i) => _rowFor(knobs[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Write `test/widgets/knob_panel_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';
import 'package:widget_library/src/widgets/knob_panel.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SizedBox(width: 400, height: 600, child: child))),
  );
}

void main() {
  testWidgets('renders one row per knob in order', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
      BoolKnob(id: 'on', label: 'Enabled', defaultValue: true),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    expect(find.byKey(const ValueKey('wl.detail.knob.h')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.knob.on')), findsOneWidget);
  });

  testWidgets('updates readback label on controller.set', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    final readback = find.byKey(const ValueKey('wl.detail.knob.h.value'));
    expect((tester.widget(readback) as Text).data, '200.0');

    c.set('h', 300.0);
    await tester.pump();

    expect((tester.widget(readback) as Text).data, '300.0');
  });

  testWidgets('reset all restores every default', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    c.set('h', 300.0);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('wl.detail.knobs.reset_all')));
    await tester.pump();

    expect(c.values['h'], 200.0);
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/widgets/knob_panel_test.dart`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/widgets/knob_panel.dart test/widgets/knob_panel_test.dart
git commit -m "feat(knobs): add KnobPanel that dispatches typed rows and global reset"
```

---

## Task 6: CatalogApp + GridScreen — entries builder function

**Goal:** Change `CatalogApp.entries` to `List<CatalogEntry> Function()` and thread it through `GridScreen` so hot reload re-invokes it. Preview of `.live` entries in the grid tile uses the builder with default values (ephemeral `KnobValues`). Breaking change; update call sites.

**Files:**
- Modify: `lib/src/catalog_app.dart`
- Modify: `lib/src/screens/grid_screen.dart`
- Modify: `test/catalog_app_test.dart` (call-site update)

**Acceptance Criteria:**
- [ ] `CatalogApp` has exactly one `entries` parameter of type `List<CatalogEntry> Function()`.
- [ ] `GridScreen.build()` invokes `widget.entriesBuilder()` each frame to derive the list.
- [ ] `_Tile` for a `.live` entry renders via `entry.builder!(ctx, KnobValues(defaults))`; legacy entries still render `entry.states.values.first`.
- [ ] `test/catalog_app_test.dart` passes with the new API.
- [ ] `flutter analyze lib/` → no errors.

**Verify:** `flutter test test/catalog_app_test.dart` → pass. `flutter analyze lib/` → clean.

**Steps:**

- [ ] **Step 1: Edit `lib/src/catalog_app.dart`**

Replace `entries` field + param:

```dart
class CatalogApp extends StatefulWidget {
  final List<CatalogEntry> Function() entries;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final String title;
  final ThemeMode initialTheme;

  const CatalogApp({
    super.key,
    required this.entries,
    this.lightTheme,
    this.darkTheme,
    this.title = 'Widget Library',
    this.initialTheme = ThemeMode.system,
  });

  // ... state unchanged except GridScreen call
}
```

In `_CatalogAppState.build`, pass the builder through:

```dart
home: GridScreen(entriesBuilder: widget.entries, title: widget.title),
```

- [ ] **Step 2: Edit `lib/src/screens/grid_screen.dart`**

Change the class signature and invoke the builder in `build`:

```dart
class GridScreen extends StatefulWidget {
  final List<CatalogEntry> Function() entriesBuilder;
  final String title;
  const GridScreen({
    super.key,
    required this.entriesBuilder,
    required this.title,
  });

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  String _query = '';
  String _category = _allCategory;
  static const _allCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final entries = widget.entriesBuilder();
    final theme = CatalogTheme.of(context);
    final cs = Theme.of(context).colorScheme;

    final categories = <String>{};
    for (final e in entries) {
      final c = e.category;
      if (c != null && c.isNotEmpty) categories.add(c);
    }
    final cats = categories.isEmpty
        ? const <String>[]
        : [_allCategory, ...categories];

    final q = _query.trim().toLowerCase();
    final filtered = entries.where((e) {
      final catOk = _category == _allCategory || e.category == _category;
      final qOk = q.isEmpty || e.name.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    final hasEntries = entries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            key: const ValueKey('wl.app_bar.theme_toggle'),
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
          if (hasEntries) ...[
            _SearchBar(
              value: _query,
              onChanged: (v) => setState(() => _query = v),
            ),
            if (cats.isNotEmpty)
              _CategoryStrip(
                categories: cats,
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),
            Divider(height: 1, color: cs.outlineVariant),
          ],
          Expanded(
            child: !hasEntries
                ? const EmptyState()
                : filtered.isEmpty
                    ? _NoMatches(query: _query)
                    : _GridBody(
                        entries: filtered,
                        entriesBuilder: widget.entriesBuilder,
                      ),
          ),
        ],
      ),
    );
  }
}
```

Thread `entriesBuilder` into `_GridBody` and `_Tile` so the DetailScreen pushed on tap receives the same builder (used by Task 7):

```dart
class _GridBody extends StatelessWidget {
  final List<CatalogEntry> entries;
  final List<CatalogEntry> Function() entriesBuilder;
  const _GridBody({required this.entries, required this.entriesBuilder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) => _Tile(
        entry: entries[i],
        entriesBuilder: entriesBuilder,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final CatalogEntry entry;
  final List<CatalogEntry> Function() entriesBuilder;
  const _Tile({required this.entry, required this.entriesBuilder});
  // ... rest unchanged except onTap navigation
}
```

Update the `InkWell.onTap`:

```dart
onTap: () => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DetailScreen(
      entryName: entry.name,
      entriesBuilder: entriesBuilder,
    ),
  ),
),
```

(The DetailScreen rewrite in Task 7 takes `entryName` + `entriesBuilder` rather than a raw `CatalogEntry`, so hot reload works through the detail route.)

- [ ] **Step 3: Update `test/catalog_app_test.dart`**

Read the existing test first, then update the `CatalogApp(...)` constructor calls to pass `entries: () => [...]` instead of `entries: [...]`. Keep every assertion as-is. Example snippet:

```dart
await tester.pumpWidget(CatalogApp(entries: () => [
  CatalogEntry(name: 'X', states: {'default': (_) => const SizedBox()}),
]));
```

- [ ] **Step 4: Run verification**

Run: `flutter analyze lib/` then `flutter test test/catalog_app_test.dart`
Expected: analyzer clean, test passes.

- [ ] **Step 5: Commit**

```bash
git add lib/src/catalog_app.dart lib/src/screens/grid_screen.dart test/catalog_app_test.dart
git commit -m "refactor(catalog): entries is now a builder fn for hot-reload safety"
```

---

## Task 7: DetailScreen — live branch + reassemble

**Goal:** Rewrite `DetailScreen` so it accepts the catalog entries builder + an `entryName`, re-derives the entry on every build (and on `reassemble`), branches on `entry.isLive`, owns a `KnobController` reconciled on reload, and renders the inline split panel.

**Files:**
- Modify: `lib/src/screens/detail_screen.dart`
- Create: `test/screens/detail_screen_live_test.dart`

**Acceptance Criteria:**
- [ ] `DetailScreen` takes `{String entryName, List<CatalogEntry> Function() entriesBuilder}`. No raw `CatalogEntry` field.
- [ ] If the named entry is not found on rebuild, shows a placeholder with message "Entry '<name>' not found" (non-fatal — useful when hot reload removes an entry).
- [ ] For `isLive == true`: body is `Column(children: [Expanded(flex:3, preview), Divider, Expanded(flex:2, KnobPanel)])`.
- [ ] Preview wraps `_entry.builder!(ctx, _knobs.readOnly)` inside `ListenableBuilder(listenable: _knobs)`.
- [ ] `reassemble()` re-derives entry, calls `_knobs.reconcile(entry.knobs ?? const [])`, calls `setState(() {})`.
- [ ] Legacy (non-live) entries render the existing variant picker + `states` map exactly as before — no regressions.

**Verify:** `flutter test test/screens/detail_screen_live_test.dart test/catalog_app_test.dart test/catalog_entry_test.dart` → all pass. Manual: `cd example && flutter run`, open Primary Button entry, drag slider, verify preview rebuilds without restart.

**Steps:**

- [ ] **Step 1: Read current `lib/src/screens/detail_screen.dart`**

Already shown in brainstorming context. Rewrite fully.

- [ ] **Step 2: Write the new `lib/src/screens/detail_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../knobs/knob_controller.dart';
import '../knobs/knob_values.dart';
import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/error_boundary.dart';
import '../widgets/knob_panel.dart';
import '../widgets/specs_panel.dart';

class DetailScreen extends StatefulWidget {
  final String entryName;
  final List<CatalogEntry> Function() entriesBuilder;

  const DetailScreen({
    super.key,
    required this.entryName,
    required this.entriesBuilder,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  KnobController? _knobs;
  String _selectedState = '';

  CatalogEntry? _lookup() {
    final list = widget.entriesBuilder();
    for (final e in list) {
      if (e.name == widget.entryName) return e;
    }
    return null;
  }

  CatalogEntry? _ensureState(CatalogEntry? entry) {
    if (entry == null) return null;
    if (entry.isLive) {
      _knobs ??= KnobController(entry.knobs!);
      _knobs!.reconcile(entry.knobs!);
    } else {
      _knobs = null;
      if (!entry.states.containsKey(_selectedState)) {
        _selectedState = entry.states.keys.first;
      }
    }
    return entry;
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _ensureState(_lookup());
    });
  }

  void _showSpecs(GlobalKey previewKey) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecsPanel(previewKey: previewKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _ensureState(_lookup());
    final theme = CatalogTheme.of(context);
    final cs = Theme.of(context).colorScheme;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.entryName)),
        body: Center(
          child: Text("Entry '${widget.entryName}' not found"),
        ),
      );
    }

    final previewKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        actions: [
          IconButton(
            key: const ValueKey('wl.app_bar.specs'),
            tooltip: 'Specs',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSpecs(previewKey),
          ),
          IconButton(
            key: const ValueKey('wl.app_bar.theme_toggle'),
            tooltip: 'Toggle theme',
            icon: Icon(
              theme.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: theme.toggle,
          ),
        ],
      ),
      body: entry.isLive
          ? _LiveBody(
              entry: entry,
              controller: _knobs!,
              previewKey: previewKey,
              surface: cs.surfaceContainerLow,
            )
          : _LegacyBody(
              entry: entry,
              selected: _selectedState,
              onSelected: (k) => setState(() => _selectedState = k),
              previewKey: previewKey,
              surface: cs.surfaceContainerLow,
              outline: cs.outlineVariant,
            ),
    );
  }
}

class _LiveBody extends StatelessWidget {
  final CatalogEntry entry;
  final KnobController controller;
  final GlobalKey previewKey;
  final Color surface;

  const _LiveBody({
    required this.entry,
    required this.controller,
    required this.previewKey,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: surface,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: entry.previewSize.width,
                    maxHeight: entry.previewSize.height,
                  ),
                  child: KeyedSubtree(
                    key: previewKey,
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (ctx, _) => ErrorBoundary(
                        builder: (inner) => entry.builder!(
                          inner,
                          KnobValues(controller.values),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(flex: 2, child: KnobPanel(controller: controller)),
      ],
    );
  }
}

class _LegacyBody extends StatelessWidget {
  final CatalogEntry entry;
  final String selected;
  final ValueChanged<String> onSelected;
  final GlobalKey previewKey;
  final Color surface;
  final Color outline;

  const _LegacyBody({
    required this.entry,
    required this.selected,
    required this.onSelected,
    required this.previewKey,
    required this.surface,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final keys = entry.states.keys.toList();
    final builder = entry.states[selected]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _VariantPicker(
            keys: keys,
            selected: selected,
            onChanged: onSelected,
          ),
        ),
        Divider(height: 1, color: outline),
        Expanded(
          child: Container(
            color: surface,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: entry.previewSize.width,
                    maxHeight: entry.previewSize.height,
                  ),
                  child: KeyedSubtree(
                    key: previewKey,
                    child: ErrorBoundary(
                      key: ValueKey(selected),
                      builder: builder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantPicker extends StatelessWidget {
  final List<String> keys;
  final String selected;
  final ValueChanged<String> onChanged;
  const _VariantPicker({
    required this.keys,
    required this.selected,
    required this.onChanged,
  });

  static const _maxSegments = 4;
  static const _maxLabelChars = 10;
  static const _maxTotalChars = 28;

  bool _fitsSegmented() {
    if (keys.length > _maxSegments) return false;
    final longest = keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);
    if (longest > _maxLabelChars) return false;
    final total = keys.fold<int>(0, (s, k) => s + k.length);
    if (total > _maxTotalChars) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_fitsSegmented()) {
      return SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            for (final k in keys)
              ButtonSegment<String>(
                value: k,
                label: Text(k, key: ValueKey('wl.detail.variant.$k')),
              ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      );
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final k = keys[i];
          return ChoiceChip(
            key: ValueKey('wl.detail.variant.$k'),
            label: Text(k),
            selected: selected == k,
            onSelected: (_) => onChanged(k),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Write `test/screens/detail_screen_live_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';
import 'package:widget_library/src/screens/detail_screen.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

Widget _wrap(Widget child) {
  final controller = ThemeController(initial: ThemeMode.light);
  return CatalogTheme(
    controller: controller,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('live entry renders knob panel; slider drag rebuilds preview',
      (tester) async {
    final entry = CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 100,
          min: 50,
          max: 300,
        ),
      ],
      builder: (ctx, v) => Container(
        key: const ValueKey('probe'),
        width: 100,
        height: v.getDouble('h'),
        color: const Color(0xFF1E88E5),
      ),
    );

    await tester.pumpWidget(_wrap(DetailScreen(
      entryName: 'Box',
      entriesBuilder: () => [entry],
    )));

    expect(find.byKey(const ValueKey('wl.detail.knob_panel')), findsOneWidget);

    Container probe() =>
        tester.widget<Container>(find.byKey(const ValueKey('probe')));

    expect(probe().constraints?.maxHeight, 100);

    await tester.drag(
      find.byKey(const ValueKey('wl.detail.knob.h.control')),
      const Offset(200, 0),
    );
    await tester.pump();

    expect(probe().constraints!.maxHeight, greaterThan(100));
  });

  testWidgets('legacy entry still renders variant picker', (tester) async {
    final entry = CatalogEntry(
      name: 'Btn',
      states: {
        'a': (_) => const Text('A'),
        'b': (_) => const Text('B'),
      },
    );

    await tester.pumpWidget(_wrap(DetailScreen(
      entryName: 'Btn',
      entriesBuilder: () => [entry],
    )));

    expect(find.byKey(const ValueKey('wl.detail.variant.a')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.variant.b')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.knob_panel')), findsNothing);
  });

  testWidgets('missing entry shows not-found placeholder', (tester) async {
    await tester.pumpWidget(_wrap(DetailScreen(
      entryName: 'Ghost',
      entriesBuilder: () => const [],
    )));

    expect(find.textContaining("'Ghost' not found"), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/screens/detail_screen_live_test.dart test/catalog_app_test.dart test/catalog_entry_test.dart`
Expected: all pass.

- [ ] **Step 5: Manual smoke check**

Run: `cd example && flutter run -d <device>` (after Task 8 migration also lands; for now an isolated smoke is optional since example not yet migrated). You can defer this step until after Task 8.

- [ ] **Step 6: Commit**

```bash
git add lib/src/screens/detail_screen.dart test/screens/detail_screen_live_test.dart
git commit -m "feat(catalog): DetailScreen live-knob branch with reassemble plumbing"
```

---

## Task 8: Migrate example Primary Button entry

**Goal:** Convert the `Primary Button` entry in `example/lib/catalog.dart` to `CatalogEntry.live`, and update `example/lib/main.dart` to pass the builder function.

**Files:**
- Modify: `example/lib/catalog.dart`
- Modify: `example/lib/main.dart`

**Acceptance Criteria:**
- [ ] `Primary Button` uses `CatalogEntry.live` with knobs `label: StringKnob`, `enabled: BoolKnob`, `loading: BoolKnob`.
- [ ] `Chip` entry unchanged (legacy `states` map) — proves additive migration.
- [ ] `main()` passes `entries: buildCatalog` (no parens).
- [ ] `flutter analyze example/` → clean.
- [ ] `flutter test test/` (at repo root) → all pass.

**Verify:** `cd example && flutter run -d <device>`; open Primary Button; drag/toggle all three knobs; each change rebuilds preview with no restart. Change `defaultValue: 'Tap me'` → `'Submit'` in `catalog.dart`, save, hot reload: Primary Button default label reads `Submit` in panel for fresh users and the preview rebuilds.

**Steps:**

- [ ] **Step 1: Edit `example/lib/catalog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'widgets/primary_button.dart';

List<CatalogEntry> buildCatalog() => [
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
      CatalogEntry(
        name: 'Chip',
        category: 'Inputs',
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

- [ ] **Step 2: Edit `example/lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'catalog.dart';

void main() {
  runApp(CatalogApp(
    entries: buildCatalog,
    lightTheme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
  ));
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze example/` then `flutter test`
Expected: no analyzer errors, all tests pass.

- [ ] **Step 4: Manual smoke**

Run: `cd example && flutter run` on a device/emulator. Confirm:
1. Primary Button tile shows in grid.
2. Opening it shows inline split: preview above, knob panel below.
3. Slider/toggle drags rebuild preview without restart.
4. Edit `defaultValue: 'Tap me'` → `'Submit'`, save. Hot reload. If you never dragged the label knob, it now reads `Submit`; if you did, your edited value persists. Use "Reset" to see the new default.
5. Chip entry still shows variant picker + states (no knob panel).

- [ ] **Step 5: Commit**

```bash
git add example/lib/catalog.dart example/lib/main.dart
git commit -m "feat(example): migrate Primary Button to CatalogEntry.live"
```

---

## Task 9: Hot-reload simulation test + exports polish

**Goal:** A widget test that simulates hot reload on a `DetailScreen` with a live entry and asserts the `reconcile` policy (preserve matching-id user values, seed new ids, drop removed, surface new defaults via reset). Export all new public types from `widget_library.dart`.

**Files:**
- Modify: `lib/widget_library.dart`
- Create: `test/screens/detail_screen_reload_test.dart`

**Acceptance Criteria:**
- [ ] `lib/widget_library.dart` re-exports `knob.dart` and `knob_values.dart`.
- [ ] `KnobController` remains internal (not exported — consumers shouldn't instantiate it directly).
- [ ] Reload simulation test passes: after swapping the closure returned by `entriesBuilder`, `tester.binding.reassembleApplication()` triggers reconcile, new defaults appear for untouched ids, previously set user values persist for matching ids.

**Verify:** `flutter test test/` → all pass. `flutter analyze` → clean.

**Steps:**

- [ ] **Step 1: Edit `lib/widget_library.dart`**

```dart
library widget_library;

export 'src/catalog_app.dart';
export 'src/knobs/knob.dart';
export 'src/knobs/knob_values.dart';
export 'src/models/catalog_entry.dart';
```

- [ ] **Step 2: Write `test/screens/detail_screen_reload_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';
import 'package:widget_library/src/screens/detail_screen.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

Widget _wrap(Widget child) {
  final controller = ThemeController(initial: ThemeMode.light);
  return CatalogTheme(
    controller: controller,
    child: MaterialApp(home: child),
  );
}

CatalogEntry _v1() => CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 100,
          min: 50,
          max: 300,
        ),
        BoolKnob(id: 'on', label: 'Enabled', defaultValue: true),
      ],
      builder: (ctx, v) => SizedBox(
        key: const ValueKey('probe'),
        height: v.getDouble('h'),
      ),
    );

CatalogEntry _v2() => CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 250, // changed default
          min: 50,
          max: 300,
        ),
        // 'on' removed
        StringKnob(id: 'label', label: 'Label', defaultValue: 'hello'),
      ],
      builder: (ctx, v) => SizedBox(
        key: const ValueKey('probe'),
        height: v.getDouble('h'),
      ),
    );

void main() {
  testWidgets('reassemble reconciles knobs and preserves user values',
      (tester) async {
    var version = 1;
    List<CatalogEntry> builder() => [version == 1 ? _v1() : _v2()];

    await tester.pumpWidget(_wrap(DetailScreen(
      entryName: 'Box',
      entriesBuilder: builder,
    )));

    // User drags height to 180.
    await tester.drag(
      find.byKey(const ValueKey('wl.detail.knob.h.control')),
      const Offset(80, 0),
    );
    await tester.pump();

    // Confirm user value took (not exact — Slider geometry-dependent).
    SizedBox probe() =>
        tester.widget<SizedBox>(find.byKey(const ValueKey('probe')));
    final userHeight = probe().height!;
    expect(userHeight, greaterThan(100));

    // Swap "source" and fire reassemble.
    version = 2;
    tester.binding.reassembleApplication();
    await tester.pump();

    // Old 'on' knob removed.
    expect(find.byKey(const ValueKey('wl.detail.knob.on')), findsNothing);
    // New 'label' knob appears.
    expect(find.byKey(const ValueKey('wl.detail.knob.label')), findsOneWidget);
    // Matching 'h' preserves user value (default change does not overwrite).
    expect(probe().height, userHeight);
  });
}
```

- [ ] **Step 3: Run verification**

Run: `flutter analyze` then `flutter test`
Expected: analyzer clean, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/widget_library.dart test/screens/detail_screen_reload_test.dart
git commit -m "test(knobs): hot-reload simulation covers reconcile policy; export types"
```

---

## Task 10: Final verification + README note

**Goal:** End-to-end check across the full repo and a short note in the top-level `README.md` pointing developers at `.live` entries and the knob panel.

**Files:**
- Modify: `README.md`

**Acceptance Criteria:**
- [ ] `flutter analyze` across root + example → clean.
- [ ] `flutter test` (root) → all pass.
- [ ] `cd example && flutter analyze && flutter test` → clean + passes.
- [ ] `README.md` has a short "Live knobs" subsection with a minimal `.live` snippet and the hot-reload loop description.

**Verify:** All commands listed above return success.

**Steps:**

- [ ] **Step 1: Read `README.md`, find the best insertion point**

Run: `flutter analyze && flutter test && cd example && flutter analyze && flutter test && cd ..`
Expected: all green.

- [ ] **Step 2: Add "Live knobs" subsection to `README.md`**

Insert under the section that documents `CatalogEntry`. Minimum content:

```markdown
### Live knobs

Declare typed knobs on an entry to get a live panel next to the preview:

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

Pass your entries as a function so Flutter hot reload can re-invoke it:

```dart
runApp(CatalogApp(entries: buildCatalog));
```

Dragging a slider rebuilds the preview live. Edits to `defaultValue` are picked up on hot reload; user-dragged values are preserved.
```

- [ ] **Step 3: Final run**

Run: `flutter analyze && flutter test`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document CatalogEntry.live and knob panel in README"
```

---

## Self-Review Results

- **Spec coverage:** §3.1–3.4 → Tasks 1, 3, 6. §4.1 → Task 2. §4.2 → Task 7. §4.3 → Tasks 4, 5. §4.4 → Task 6. §5 → Tasks 6, 7, 9. §6 keys → Tasks 4, 5, 7. §7 file list matches task file list. §8 migration → Task 8. §9 tests → Tasks 1, 2, 3, 5, 7, 9. §10 out-of-scope respected (no persistence, no URL share, no drag handle, no other entries, no widgetbook).
- **Placeholder scan:** none found.
- **Type consistency:** `entriesBuilder` param name used consistently across `CatalogApp`, `GridScreen`, `_Tile`, `DetailScreen`. `KnobController.reconcile`, `resetAll`, `readOnly` match across tasks. `CatalogEntry.isLive`/`knobs`/`builder` getter names match across tasks. `KnobValues` getter names (`getDouble`, `getInt`, `getBool`, `getString`, `getColor`, `getEnum<T>`, `valueOf<T>`) match across tasks. Key namespace `wl.detail.knob.<id>.*` consistent across row widgets and tests.
