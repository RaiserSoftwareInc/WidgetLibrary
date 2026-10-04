import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class IntRow extends StatelessWidget {
  final IntKnob knob;
  final KnobController controller;

  const IntRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id]! as int;
    final divisions = ((knob.max - knob.min) / knob.step).round();

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
                '$value',
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
            min: knob.min.toDouble(),
            max: knob.max.toDouble(),
            divisions: divisions,
            value: value.toDouble().clamp(
                  knob.min.toDouble(),
                  knob.max.toDouble(),
                ),
            onChanged: (v) => controller.set(knob.id, v.round()),
          ),
        ],
      ),
    );
  }
}
