import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/error_boundary.dart';
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
    final previewBuilder = entry.states.values.first;
    final preview = entry.thumbnail ??
        FittedBox(
          fit: BoxFit.contain,
          child: ErrorBoundary(builder: previewBuilder),
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
