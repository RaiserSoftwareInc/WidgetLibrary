import 'package:flutter/material.dart';

class SpecsPanel extends StatelessWidget {
  final GlobalKey previewKey;
  const SpecsPanel({super.key, required this.previewKey});

  @override
  Widget build(BuildContext context) {
    final ctx = previewKey.currentContext;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Built once per SpecsPanel build, outside the sheet builder. The sheet
    // re-invokes its builder on every drag frame; reusing the same widget
    // instances (and list) lets Flutter skip rebuilding the sections.
    final List<Widget> sections = [
      _SizeSection(previewContext: ctx),
      const SizedBox(height: 16),
      _ThemeSection(source: context),
      const SizedBox(height: 16),
      _TreeSection(lines: ctx == null ? const [] : _walk(ctx)),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Specs', style: text.titleMedium),
              ),
              Divider(height: 1, color: cs.outlineVariant),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: sections,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: text.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeSection extends StatelessWidget {
  final BuildContext? previewContext;
  const _SizeSection({required this.previewContext});

  @override
  Widget build(BuildContext context) {
    Size? size;
    final ro = previewContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) size = ro.size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Size'),
        if (size == null)
          const _Row(label: 'size', value: 'not laid out yet')
        else ...[
          _Row(
            label: 'width × height',
            value: '${size.width.toStringAsFixed(1)} × '
                '${size.height.toStringAsFixed(1)} px',
          ),
        ],
      ],
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final BuildContext source;
  const _ThemeSection({required this.source});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(source).colorScheme;
    final tt = Theme.of(source).textTheme;

    String hex(Color c) {
      final v = c.toARGB32() & 0xFFFFFF;
      return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    }

    String fs(TextStyle? s) {
      if (s == null) return '—';
      final size = s.fontSize?.toStringAsFixed(1) ?? '?';
      final weight = s.fontWeight?.value ?? 400;
      return '$size px · w$weight';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Theme tokens'),
        _Row(label: 'primary', value: hex(cs.primary)),
        _Row(label: 'surface', value: hex(cs.surface)),
        _Row(label: 'onSurface', value: hex(cs.onSurface)),
        _Row(label: 'outline', value: hex(cs.outline)),
        _Row(label: 'titleMedium', value: fs(tt.titleMedium)),
        _Row(label: 'bodyMedium', value: fs(tt.bodyMedium)),
        _Row(label: 'labelSmall', value: fs(tt.labelSmall)),
      ],
    );
  }
}

const _maxDepth = 6;
const _maxNodes = 40;

List<_TreeLine> _walk(BuildContext ctx) {
  final lines = <_TreeLine>[];
  void visit(Element e, int depth) {
    if (lines.length >= _maxNodes || depth > _maxDepth) return;
    final node = e.widget.toDiagnosticsNode();
    final props = node
        .getProperties()
        .where((p) => !p.isFiltered(DiagnosticLevel.info))
        .take(3)
        .map((p) => p.toString())
        .join(', ');
    lines.add(_TreeLine(
      depth: depth,
      name: e.widget.runtimeType.toString(),
      props: props,
    ),);
    e.visitChildren((c) => visit(c, depth + 1));
  }

  visit(ctx as Element, 0);
  return lines;
}

class _TreeSection extends StatelessWidget {
  final List<_TreeLine> lines;
  const _TreeSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Widget tree'),
        if (lines.isEmpty)
          const _Row(label: 'tree', value: 'unavailable')
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        '${'  ' * line.depth}${line.name}'
                        '${line.props.isEmpty ? '' : '  (${line.props})'}',
                        style: text.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurface,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TreeLine {
  final int depth;
  final String name;
  final String props;
  const _TreeLine({required this.depth, required this.name, required this.props});
}
