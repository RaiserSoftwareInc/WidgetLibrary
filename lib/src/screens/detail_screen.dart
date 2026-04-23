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
