import 'package:flutter/material.dart';

import '../knobs/knob_controller.dart';
import '../models/catalog_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/error_boundary.dart';
import '../widgets/knob_panel.dart';
import '../widgets/specs_panel.dart';

class DetailScreen extends StatefulWidget {
  final String entryName;
  final List<CatalogEntry> Function() entriesBuilder;

  const DetailScreen({
    super.key,
    required this.entryName,
    required this.entriesBuilder,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  KnobController? _knobs;
  String _selectedState = '';

  CatalogEntry? _lookup() {
    final list = widget.entriesBuilder();
    for (final e in list) {
      if (e.name == widget.entryName) return e;
    }
    return null;
  }

  CatalogEntry? _ensureState(CatalogEntry? entry) {
    if (entry == null) return null;
    if (entry.isLive) {
      _knobs ??= KnobController(entry.knobs!);
      _knobs!.reconcile(entry.knobs!);
    } else {
      _knobs = null;
      if (!entry.states.containsKey(_selectedState)) {
        _selectedState = entry.states.keys.first;
      }
    }
    return entry;
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _ensureState(_lookup());
    });
  }

  void _showSpecs(GlobalKey previewKey) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecsPanel(previewKey: previewKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _ensureState(_lookup());
    final theme = CatalogTheme.of(context);
    final cs = Theme.of(context).colorScheme;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.entryName)),
        body: Center(
          child: Text("Entry '${widget.entryName}' not found"),
        ),
      );
    }

    final previewKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        actions: [
          IconButton(
            key: const ValueKey('wl.app_bar.specs'),
            tooltip: 'Specs',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSpecs(previewKey),
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
      body: entry.isLive
          ? _LiveBody(
              entry: entry,
              controller: _knobs!,
              previewKey: previewKey,
              surface: cs.surfaceContainerLow,
            )
          : _LegacyBody(
              entry: entry,
              selected: _selectedState,
              onSelected: (k) => setState(() => _selectedState = k),
              previewKey: previewKey,
              surface: cs.surfaceContainerLow,
              outline: cs.outlineVariant,
            ),
    );
  }
}

class _LiveBody extends StatelessWidget {
  final CatalogEntry entry;
  final KnobController controller;
  final GlobalKey previewKey;
  final Color surface;

  const _LiveBody({
    required this.entry,
    required this.controller,
    required this.previewKey,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: surface,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: entry.previewSize.width,
                    maxHeight: entry.previewSize.height,
                  ),
                  child: KeyedSubtree(
                    key: previewKey,
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (ctx, _) => ErrorBoundary(
                        builder: (inner) => entry.builder!(
                          inner,
                          controller.readOnly,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(flex: 2, child: KnobPanel(controller: controller)),
      ],
    );
  }
}

class _LegacyBody extends StatelessWidget {
  final CatalogEntry entry;
  final String selected;
  final ValueChanged<String> onSelected;
  final GlobalKey previewKey;
  final Color surface;
  final Color outline;

  const _LegacyBody({
    required this.entry,
    required this.selected,
    required this.onSelected,
    required this.previewKey,
    required this.surface,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final keys = entry.states.keys.toList();
    final builder = entry.states[selected]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _VariantPicker(
            keys: keys,
            selected: selected,
            onChanged: onSelected,
          ),
        ),
        Divider(height: 1, color: outline),
        Expanded(
          child: Container(
            color: surface,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: entry.previewSize.width,
                    maxHeight: entry.previewSize.height,
                  ),
                  child: KeyedSubtree(
                    key: previewKey,
                    child: ErrorBoundary(
                      key: ValueKey(selected),
                      builder: builder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
