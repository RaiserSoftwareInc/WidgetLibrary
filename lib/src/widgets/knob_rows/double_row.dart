import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';
import 'knob_value_builder.dart';

class DoubleRow extends StatelessWidget {
  final DoubleKnob knob;
  final KnobController controller;

  const DoubleRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    final divisions = knob.step != null
        ? ((knob.max - knob.min) / knob.step!).round()
        : null;

    return KnobValueBuilder(
      controller: controller,
      id: knob.id,
      builder: (context, raw) {
        final value = raw! as double;
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
                    value.toStringAsFixed(1),
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
              Slider(
                key: ValueKey('wl.detail.knob.${knob.id}.control'),
                min: knob.min,
                max: knob.max,
                divisions: divisions,
                value: value.clamp(knob.min, knob.max),
                onChanged: (v) => controller.set(knob.id, v),
              ),
            ],
          ),
        );
      },
    );
  }
}
