# Marionette bindings for the main page — design

**Date:** 2026-05-22
**Status:** Approved (pending spec review)

## Problem

The widget catalog shell is keyed for [Marionette MCP](https://marionette.leancode.co/)
so an AI agent can drive the viewer. Two gaps reduce how well an agent can operate
the **main (grid) page**:

1. The example app (`example/lib/main.dart`) never calls
   `MarionetteBinding.ensureInitialized()`. The README documents this as the
   consumer's responsibility, but the shipped demo is therefore *not*
   agent-drivable out of the box — anyone evaluating the catalog with Marionette
   has to wire it themselves first.
2. Several grid surfaces an agent interacts with have no `wl.*` ValueKey:
   the no-matches state, the screen root, and the current match count.

## Goals

- Make the example app agent-drivable in debug with zero extra setup.
- Add the missing grid ValueKeys so an agent can: detect a dead-end search,
  confirm which screen it is on, and read the match count.
- No breaking change to the library's public API. (See
  `memory/feedback_api_breaks.md`: git-ref consumers exist; prefer additive.)

## Non-goals

- No change to the core library's runtime dependencies — Marionette stays a
  *consumer-side* dev dependency, exactly as today.
- No new agent capabilities beyond keying existing surfaces.

## Part 1 — Wire `MarionetteBinding` in the example app

`example/lib/main.dart` becomes:

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

- Add `marionette_flutter: ^0.5.0` to `example/pubspec.yaml` under
  `dev_dependencies`.
- The `kDebugMode` guard ensures release builds use the plain Flutter binding —
  Marionette is debug-only.
- **Verified (2026-05-22):** `marionette_flutter` and `marionette_mcp` latest =
  `0.5.0` on pub.dev (publisher leancode.co). `MarionetteBinding.ensureInitialized()`
  is the current, documented init API. No breaking changes or deprecations since
  `0.5.0`. The `^0.5.0` pin is up to date.
- **Test-conflict note:** pub.dev warns `MarionetteBinding.ensureInitialized()`
  can conflict with `flutter_test`; the fix is a `FLUTTER_TEST` env guard or a
  separate test entrypoint. Our tests pump `CatalogApp` directly (never
  `example/lib/main.dart`), so the binding never loads under test and no guard is
  needed today. If tests are ever widened to drive `main()`, add the
  `FLUTTER_TEST` guard.

## Part 2 — Missing grid ValueKeys

All new keys are `wl.*` namespaced. New multi-segment keys use the `wl.grid.*`
prefix to match the existing `wl.detail.*` convention (the older flat grid keys
like `wl.search_field` are left as-is for back-compat).

| Surface | New key | Purpose |
| --- | --- | --- |
| `_NoMatches` (search/filter dead-end) | `wl.grid.no_matches` | distinguish "no results" from a render failure |
| Grid `Scaffold` root | `wl.grid_screen` | agent confirms it is on the home screen |
| Detail `Scaffold` root | `wl.detail_screen` | agent confirms it is on the detail screen (symmetry) |
| Match-count label | `wl.grid.result_count` | read match count without enumerating tiles |

### Result-count label (visible)

A subtle line rendered below the category strip whenever entries exist, showing
the count of `filtered` entries, e.g. `12 results` (`1 result` singular). Styled
with `textTheme.labelSmall` + `onSurfaceVariant`, low padding. Carries
`ValueKey('wl.grid.result_count')`. Visible to humans and readable by the agent.

When `filtered.isEmpty` but entries exist, the `_NoMatches` widget (`wl.grid.no_matches`) renders; an entirely empty catalog renders the `EmptyState` (`wl.empty_state.copy`) instead.

## Documentation

Append four rows to the README "Keys exposed by the shell" table:

| Surface | Key |
| --- | --- |
| Grid screen root | `wl.grid_screen` |
| Detail screen root | `wl.detail_screen` |
| No-matches state | `wl.grid.no_matches` |
| Result count | `wl.grid.result_count` |

## Testing (TDD — write assertions first)

Extend `test/marionette_keys_test.dart`:

- Grid test: assert `wl.grid_screen` and `wl.grid.result_count` are present;
  assert the count text matches the number of entries.
- New test: filter to zero matches (type a query that matches nothing), assert
  `wl.grid.no_matches` is present and `wl.grid.result_count` reads `0`.
- Detail test: assert `wl.detail_screen` is present after navigating in.

## Files touched

- `example/lib/main.dart` — Marionette binding wiring
- `example/pubspec.yaml` — `marionette_flutter` dev dependency
- `lib/src/screens/grid_screen.dart` — `wl.grid_screen`, `wl.grid.no_matches`,
  `wl.grid.result_count`
- `lib/src/screens/detail_screen.dart` — `wl.detail_screen`
- `README.md` — keys table
- `test/marionette_keys_test.dart` — assertions
- `CHANGELOG.md` — entry
