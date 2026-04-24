import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/empty_state.dart';
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
  String _query = '';
  String _category = _allCategory;
  static const _allCategory = 'All';

  List<String> get _categories {
    final set = <String>{};
    for (final e in widget.entries) {
      final c = e.category;
      if (c != null && c.isNotEmpty) set.add(c);
    }
    if (set.isEmpty) return const [];
    return [_allCategory, ...set];
  }

  List<CatalogEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    return widget.entries.where((e) {
      final catOk = _category == _allCategory || e.category == _category;
      final qOk = q.isEmpty || e.name.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CatalogTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final cats = _categories;
    final hasEntries = widget.entries.isNotEmpty;
    final filtered = _filtered;

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
                    : _GridBody(entries: filtered),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('wl.search_field'),
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Search widgets',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = categories[i];
          return FilterChip(
            key: ValueKey('wl.category_chip.$c'),
            label: Text(c),
            selected: selected == c,
            onSelected: (_) => onSelected(c),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final String query;
  const _NoMatches({required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No matches for "$query"',
              style: text.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different term or clear filters.',
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
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
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final previewBuilder = entry.states.values.first;
    final preview = entry.thumbnail ??
        FittedBox(
          fit: BoxFit.contain,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: entry.previewSize.width,
              maxHeight: entry.previewSize.height,
            ),
            child: ErrorBoundary(builder: previewBuilder),
          ),
        );

    return Material(
      key: ValueKey('wl.grid_tile.${entry.name}'),
      color: cs.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: cs.surfaceContainerLow,
                padding: const EdgeInsets.all(12),
                child: IgnorePointer(child: Center(child: preview)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.states.length}',
                    style: text.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
