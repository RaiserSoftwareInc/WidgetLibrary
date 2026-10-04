import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';
import 'knob_value_builder.dart';

class ColorRow extends StatelessWidget {
  final ColorKnob knob;
  final KnobController controller;

  const ColorRow({super.key, required this.knob, required this.controller});

  static const _defaultSwatches = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final swatches = knob.swatches ?? _defaultSwatches;
    final cs = Theme.of(context).colorScheme;

    return KnobValueBuilder(
      controller: controller,
      id: knob.id,
      builder: (context, raw) {
        final value = raw! as Color;
        return Padding(
          key: ValueKey('wl.detail.knob.${knob.id}'),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(knob.label)),
                  Text(
                    '#${value.toARGB32().toRadixString(16).padLeft(8, '0')}',
                    key: ValueKey('wl.detail.knob.${knob.id}.value'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  IconButton(
                    key: ValueKey('wl.detail.knob.${knob.id}.reset'),
                    tooltip: 'Reset',
                    icon: const Icon(Icons.restart_alt, size: 18),
                    onPressed: () => controller.reset(knob.id),
                  ),
                ],
              ),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  key: ValueKey('wl.detail.knob.${knob.id}.control'),
                  scrollDirection: Axis.horizontal,
                  itemCount: swatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final c = swatches[i];
                    final selected = c.toARGB32() == value.toARGB32();
                    return GestureDetector(
                      key: ValueKey(
                        'wl.detail.knob.${knob.id}.swatch.'
                        '${c.toARGB32().toRadixString(16)}',
                      ),
                      onTap: () => controller.set(knob.id, c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? cs.primary : cs.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
