import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/error_boundary.dart';
import '../widgets/specs_panel.dart';

class DetailScreen extends StatefulWidget {
  final CatalogEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _selected = widget.entry.states.keys.first;
  final GlobalKey _previewKey = GlobalKey();

  void _showSpecs() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecsPanel(previewKey: _previewKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CatalogTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final keys = widget.entry.states.keys.toList();
    final builder = widget.entry.states[_selected]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        actions: [
          IconButton(
            key: const ValueKey('wl.app_bar.specs'),
            tooltip: 'Specs',
            icon: const Icon(Icons.info_outline),
            onPressed: _showSpecs,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _VariantPicker(
              keys: keys,
              selected: _selected,
              onChanged: (k) => setState(() => _selected = k),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Expanded(
            child: Container(
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.entry.previewSize.width,
                      maxHeight: widget.entry.previewSize.height,
                    ),
                    child: KeyedSubtree(
                      key: _previewKey,
                      child: ErrorBoundary(
                        key: ValueKey(_selected),
                        builder: builder,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
