import 'package:flutter/material.dart';

import 'models/catalog_entry.dart';
import 'screens/grid_screen.dart';
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
            home: GridScreen(entries: widget.entries, title: widget.title),
          );
        },
      ),
    );
  }
}
