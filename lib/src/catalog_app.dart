import 'package:flutter/material.dart';

import 'models/catalog_entry.dart';
import 'screens/grid_screen.dart';
import 'theme/theme_controller.dart';

class CatalogApp extends StatefulWidget {
  final List<CatalogEntry> Function() entries;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final String title;

  /// Starting theme mode. Defaults to [ThemeMode.system]: resolves to
  /// light/dark at boot based on [PlatformDispatcher.platformBrightness].
  /// The user can still toggle it in-app.
  final ThemeMode initialTheme;

  const CatalogApp({
    super.key,
    required this.entries,
    this.lightTheme,
    this.darkTheme,
    this.title = 'Widget Library',
    this.initialTheme = ThemeMode.system,
  });

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
              entriesBuilder: widget.entries,
              title: widget.title,
            ),
          );
        },
      ),
    );
  }
}
