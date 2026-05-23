# Marionette Main-Page Bindings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the example catalog app Marionette-drivable out of the box and add the missing grid/detail ValueKeys so an AI agent can detect dead-end searches, confirm which screen it is on, and read the match count.

**Architecture:** Two independent changes. (1) Example app `main.dart` wires `MarionetteBinding.ensureInitialized()` under a `kDebugMode` guard, with `marionette_flutter` added as an example-only dev dependency — the core library gains no new dependency. (2) `grid_screen.dart` and `detail_screen.dart` get additive `wl.*` ValueKeys plus a visible result-count label. All changes are additive; no public API breaks.

**Tech Stack:** Flutter, Dart, `flutter_test`, `marionette_flutter ^0.5.0`.

**Spec:** `docs/superpowers/specs/2026-05-22-marionette-main-page-bindings-design.md`

---

### Task 1: Grid screen ValueKeys + visible result-count label

**Goal:** Add `wl.grid_screen` (Scaffold root), `wl.grid.no_matches` (dead-end search), and a visible `wl.grid.result_count` label to the grid screen, driven by tests.

**Files:**
- Modify: `lib/src/screens/grid_screen.dart` (Scaffold ~line 51, `_NoMatches` ~line 174, header column ~lines 65-79)
- Test: `test/marionette_keys_test.dart`

**Acceptance Criteria:**
- [ ] `wl.grid_screen` key present on the grid Scaffold
- [ ] `wl.grid.no_matches` key present when a query matches nothing
- [ ] `wl.grid.result_count` label visible under the category strip, text reads `N results` (singular `1 result`), reflecting `filtered.length`
- [ ] All existing grid keys still present (`wl.search_field`, `wl.category_chip.*`, `wl.grid_tile.*`, `wl.app_bar.theme_toggle`)

**Verify:** `flutter test test/marionette_keys_test.dart` → all pass

**Steps:**

- [ ] **Step 1: Write failing tests** — add to `test/marionette_keys_test.dart` inside `main()`:

```dart
testWidgets('grid exposes screen root + result count keys', (tester) async {
  await tester.pumpWidget(CatalogApp(
    entriesBuilder: () => [
      _entry('Button', category: 'Inputs'),
      _entry('Card', category: 'Surfaces'),
    ],
  ),);

  expect(find.byKey(const ValueKey('wl.grid_screen')), findsOneWidget);
  final count = find.byKey(const ValueKey('wl.grid.result_count'));
  expect(count, findsOneWidget);
  expect(
    tester.widget<Text>(count).data,
    '2 results',
  );
});

testWidgets('grid exposes no_matches key on dead-end search', (tester) async {
  await tester.pumpWidget(CatalogApp(
    entriesBuilder: () => [_entry('Button', category: 'Inputs')],
  ),);

  await tester.enterText(
    find.byKey(const ValueKey('wl.search_field')),
    'zzzznope',
  );
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('wl.grid.no_matches')), findsOneWidget);
  expect(
    tester.widget<Text>(find.byKey(const ValueKey('wl.grid.result_count'))).data,
    '0 results',
  );
});
```

- [ ] **Step 2: Run tests, verify they FAIL**

Run: `flutter test test/marionette_keys_test.dart`
Expected: FAIL — `wl.grid_screen` / `wl.grid.result_count` / `wl.grid.no_matches` not found.

- [ ] **Step 3: Key the Scaffold root** — in `lib/src/screens/grid_screen.dart`, change the `_GridScreenState.build` return:

```dart
    return Scaffold(
      key: const ValueKey('wl.grid_screen'),
      appBar: AppBar(
```

- [ ] **Step 4: Add the result-count label** — in the `body` Column, inside the `if (hasEntries) ...[` block, after the `Divider(...)` line, add a count line. Replace:

```dart
            Divider(height: 1, color: cs.outlineVariant),
          ],
```

with:

```dart
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'}',
                  key: const ValueKey('wl.grid.result_count'),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
```

- [ ] **Step 5: Key the no-matches state** — in `_NoMatches.build`, add the key to the outer `Center`:

```dart
    return Center(
      key: const ValueKey('wl.grid.no_matches'),
      child: Padding(
```

- [ ] **Step 6: Run tests, verify they PASS**

Run: `flutter test test/marionette_keys_test.dart`
Expected: PASS (both new tests + existing `grid surfaces expose stable Marionette keys`).

- [ ] **Step 7: Commit**

```bash
git add lib/src/screens/grid_screen.dart test/marionette_keys_test.dart
git commit -m "feat(grid): add wl.grid_screen, no_matches, result_count Marionette keys"
```

---

### Task 2: Detail screen root ValueKey

**Goal:** Add `wl.detail_screen` to the detail screen Scaffold(s) so an agent confirms it is on the detail view, driven by a test.

**Files:**
- Modify: `lib/src/screens/detail_screen.dart` (Scaffold ~line 110, and the not-found/error branch Scaffold ~line 102)
- Test: `test/marionette_keys_test.dart`

**Acceptance Criteria:**
- [ ] `wl.detail_screen` key present after navigating into an entry
- [ ] Existing detail keys still present (`wl.app_bar.specs`, `wl.detail.variant.*`)

**Verify:** `flutter test test/marionette_keys_test.dart` → all pass

**Steps:**

- [ ] **Step 1: Write failing test** — add to `test/marionette_keys_test.dart`:

```dart
testWidgets('detail exposes screen root key', (tester) async {
  final entry = CatalogEntry(name: 'Button', states: {
    'default': (_) => const Text('STATE-default'),
  },);
  await tester.pumpWidget(CatalogApp(entriesBuilder: () => [entry]));
  await tester.tap(find.text('Button'));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('wl.detail_screen')), findsOneWidget);
});
```

- [ ] **Step 2: Run test, verify it FAILS**

Run: `flutter test test/marionette_keys_test.dart`
Expected: FAIL — `wl.detail_screen` not found.

- [ ] **Step 3: Key both Scaffolds** — in `lib/src/screens/detail_screen.dart`, add the key to the not-found branch (~line 102) and the main branch (~line 110). Only one renders at a time, so the key stays unique:

```dart
      return Scaffold(
        key: const ValueKey('wl.detail_screen'),
        appBar: AppBar(title: Text(widget.entryName)),
```

and

```dart
    return Scaffold(
      key: const ValueKey('wl.detail_screen'),
      appBar: AppBar(
```

- [ ] **Step 4: Run test, verify it PASSES**

Run: `flutter test test/marionette_keys_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/screens/detail_screen.dart test/marionette_keys_test.dart
git commit -m "feat(detail): add wl.detail_screen Marionette key"
```

---

### Task 3: Wire MarionetteBinding in the example app

**Goal:** The example app initializes Marionette in debug so it is agent-drivable out of the box, with `marionette_flutter` as an example-only dev dependency.

**Files:**
- Modify: `example/lib/main.dart`
- Modify: `example/pubspec.yaml` (dev_dependencies)

**Acceptance Criteria:**
- [ ] `example/pubspec.yaml` lists `marionette_flutter: ^0.5.0` under `dev_dependencies`
- [ ] `main()` calls `MarionetteBinding.ensureInitialized()` only under `kDebugMode`, else `WidgetsFlutterBinding.ensureInitialized()`
- [ ] `flutter pub get` resolves in `example/`
- [ ] `flutter analyze` clean in `example/`

**Verify:** `cd example && flutter pub get && flutter analyze`

**Steps:**

- [ ] **Step 1: Add the dev dependency** — in `example/pubspec.yaml`, under `dev_dependencies`, add:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  marionette_flutter: ^0.5.0
```

- [ ] **Step 2: Resolve dependencies**

Run: `cd example; flutter pub get`
Expected: resolves with no errors. If `marionette_flutter` fails to resolve, stop and report — do not invent an alternate API.

- [ ] **Step 3: Wire the binding** — replace the contents of `example/lib/main.dart` with:

```dart
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
  runApp(CatalogApp(
    entriesBuilder: buildCatalog,
    lightTheme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
  ));
}
```

- [ ] **Step 4: Analyze**

Run: `cd example; flutter analyze`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add example/lib/main.dart example/pubspec.yaml example/pubspec.lock
git commit -m "feat(example): wire MarionetteBinding in debug for agent-driving"
```

---

### Task 4: Docs — README keys table + CHANGELOG + version bump

**Goal:** Document the four new keys and record the release.

**Files:**
- Modify: `README.md` (keys table ~lines 374-388)
- Modify: `CHANGELOG.md` (new section at top, ~line 5)
- Modify: `pubspec.yaml` (version ~line 3)

**Acceptance Criteria:**
- [ ] README "Keys exposed by the shell" table has rows for `wl.grid_screen`, `wl.detail_screen`, `wl.grid.no_matches`, `wl.grid.result_count`
- [ ] CHANGELOG has a `0.7.0` section describing the new keys + example wiring
- [ ] `pubspec.yaml` version bumped `0.6.2` → `0.7.0` (additive feature)

**Verify:** `flutter test` (full suite) → all pass; visual diff of README/CHANGELOG

**Steps:**

- [ ] **Step 1: Update README keys table** — in `README.md`, after the `Empty-state copy button` row, add:

```markdown
| Grid screen root | `wl.grid_screen` |
| Detail screen root | `wl.detail_screen` |
| No-matches state | `wl.grid.no_matches` |
| Result count (visible label) | `wl.grid.result_count` |
```

- [ ] **Step 2: Add CHANGELOG entry** — in `CHANGELOG.md`, insert above the `## 0.6.2` section:

```markdown
## 0.7.0 — 2026-05-22

### Added
- **Marionette keys for the main (grid) page.** `wl.grid_screen` and
  `wl.detail_screen` screen-root markers, `wl.grid.no_matches` for dead-end
  searches, and a visible `wl.grid.result_count` label (e.g. `12 results`).
  Lets an AI agent confirm the active screen, detect empty searches, and read
  the match count without enumerating tiles.
- **Example app wires `MarionetteBinding` in debug.** `example/lib/main.dart`
  now calls `MarionetteBinding.ensureInitialized()` under `kDebugMode` (with
  `marionette_flutter` as an example-only dev dependency), so the demo is
  agent-drivable out of the box. The core library gains no new dependency.

```

- [ ] **Step 3: Bump version** — in `pubspec.yaml`:

```yaml
version: 0.7.0
```

- [ ] **Step 4: Run full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md pubspec.yaml
git commit -m "docs: document main-page Marionette keys; bump 0.7.0"
```

---

## Notes

- All changes additive — no public API break (per `memory/feedback_api_breaks.md`).
- `marionette_flutter`/`marionette_mcp` `0.5.0` confirmed current on pub.dev (2026-05-22); `MarionetteBinding.ensureInitialized()` is the current API; no deprecations.
- Test-conflict caveat: tests pump `CatalogApp` directly (never `main()`), so the binding never loads under `flutter_test`. No `FLUTTER_TEST` guard needed today.
