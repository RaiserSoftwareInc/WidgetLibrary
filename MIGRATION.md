# Migration Guide

## 0.5.x → 0.6.1

TL;DR — **nothing is forced.** Your existing call site compiles and runs on
0.6.1. If you want hot-reload-friendly entry registration and the new live-
knob API, migrate `entries` → `entriesBuilder` at your own pace.

### What changed

- New live-knob system: `CatalogEntry.live(...)` with typed knobs
  (`DoubleKnob`, `IntKnob`, `BoolKnob`, `StringKnob`, `EnumKnob<T>`,
  `ColorKnob`). Purely additive — legacy `CatalogEntry(...)` with a
  `states` map still works unchanged.
- `CatalogApp` now accepts **two** mutually-exclusive registration shapes:
  - `entries: List<CatalogEntry>` — the original 0.5.x shape, now
    `@Deprecated('Use entriesBuilder for hot-reload support — removed in 1.0.0')`.
    Your `entries: buildCatalog()` call site keeps compiling.
  - `entriesBuilder: List<CatalogEntry> Function()` — new. The shell
    invokes it on every build, so edits to entry defaults (e.g. a knob's
    `defaultValue`) are picked up by Flutter hot reload without a full
    restart.
- `CatalogApp` asserts at construction that exactly one is provided.

### What you have to do

Nothing right now. Both of these compile:

```dart
// 0.5.x — still works
runApp(CatalogApp(entries: buildCatalog()));

// 0.6.1 recommended
runApp(CatalogApp(entriesBuilder: buildCatalog));
```

### What you should do before 1.0.0

Rename once per call site: replace `entries:` with `entriesBuilder:` and
drop the trailing `()` from your builder function.

```diff
- runApp(CatalogApp(entries: buildCatalog()));
+ runApp(CatalogApp(entriesBuilder: buildCatalog));
```

The rename is mechanical. Your `buildCatalog` function stays identical.

### If you were on 0.6.0

0.6.0 had `entries: List<CatalogEntry> Function()` as the only shape. If
you already changed call sites to pass a function reference, you have two
choices:

```diff
// Option A: stay on the new path, just rename the param
- CatalogApp(entries: buildCatalog)
+ CatalogApp(entriesBuilder: buildCatalog)
```

```diff
// Option B: revert to legacy (not recommended — loses hot-reload pickup)
- CatalogApp(entries: buildCatalog)
+ CatalogApp(entries: buildCatalog())
```

Option A is recommended.

### If you want live knobs on an entry

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

Legacy `CatalogEntry(name:, states:)` entries and `CatalogEntry.live(...)`
entries coexist in the same catalog — migrate one widget at a time.

### Removal schedule

- `entries: List<CatalogEntry>` is deprecated in 0.6.1. Removal in **1.0.0**.
- Analyzer will surface `deprecated_member_use` on the legacy call site —
  treat that as your migration prompt.
