import 'package:flutter/material.dart';

import 'models/catalog_entry.dart';
import 'screens/grid_screen.dart';
import 'theme/theme_controller.dart';

class CatalogApp extends StatefulWidget {
  /// Static list of entries. Use this for the classic 0.5.x call site
  /// (`entries: buildCatalog()`). Hot reload will NOT pick up edits to
  /// entry defaults unless the app is restarted. For hot-reload-safe
  /// registration, use [entriesBuilder] instead.
  @Deprecated('Use entriesBuilder for hot-reload support — removed in 1.0.0')
  final List<CatalogEntry>? entries;

  /// Builder that returns the catalog on every frame. Invoked inside
  /// `build()` so Flutter hot reload re-runs it and picks up edits to
  /// `defaultValue`s and entry lists without a full app restart. Pass a
  /// function reference: `entriesBuilder: buildCatalog`.
  final List<CatalogEntry> Function()? entriesBuilder;

  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final String title;

  /// Starting theme mode. Defaults to [ThemeMode.system]: resolves to
  /// light/dark at boot based on [PlatformDispatcher.platformBrightness].
  /// The user can still toggle it in-app.
  final ThemeMode initialTheme;

  const CatalogApp({
    super.key,
    @Deprecated('Use entriesBuilder for hot-reload support — removed in 1.0.0')
    this.entries,
    this.entriesBuilder,
    this.lightTheme,
    this.darkTheme,
    this.title = 'Widget Library',
    this.initialTheme = ThemeMode.system,
  }) : assert(
          entries != null || entriesBuilder != null,
          'CatalogApp: provide entries (List) or entriesBuilder (Function)',
        );

  /// Internal: single-path accessor used by [GridScreen]. Prefers
  /// [entriesBuilder] when both are supplied (caller opted in to the new
  /// API); falls back to wrapping the legacy list.
  List<CatalogEntry> Function() get _resolvedBuilder {
    final builder = entriesBuilder;
    if (builder != null) return builder;
    final legacy = entries!;
    return () => legacy;
  }

  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> {
  late final ThemeController _controller =
      ThemeController(initial: _resolveInitial(widget.initialTheme));

  static ThemeMode _resolveInitial(ThemeMode mode) {
    if (mode != ThemeMode.system) return mode;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

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
            home: GridScreen(
              entriesBuilder: widget._resolvedBuilder,
              title: widget.title,
            ),
          );
        },
      ),
    );
  }
}
