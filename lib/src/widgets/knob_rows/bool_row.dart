import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';
import 'knob_value_builder.dart';

class BoolRow extends StatelessWidget {
  final BoolKnob knob;
  final KnobController controller;

  const BoolRow({super.key, required this.knob, required this.controller});

  @override
  Widget build(BuildContext context) {
    return KnobValueBuilder(
      controller: controller,
      id: knob.id,
      builder: (context, raw) {
        final value = raw! as bool;
        return Padding(
          key: ValueKey('wl.detail.knob.${knob.id}'),
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Expanded(child: Text(knob.label)),
              Text(
                value ? 'on' : 'off',
                key: ValueKey('wl.detail.knob.${knob.id}.value'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Switch(
                key: ValueKey('wl.detail.knob.${knob.id}.control'),
                value: value,
                onChanged: (v) => controller.set(knob.id, v),
              ),
              IconButton(
                key: ValueKey('wl.detail.knob.${knob.id}.reset'),
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt, size: 18),
                onPressed: () => controller.reset(knob.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
