import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';
import 'knob_value_builder.dart';

class EnumRow<T> extends StatelessWidget {
  final EnumKnob<T> knob;
  final KnobController controller;

  const EnumRow({super.key, required this.knob, required this.controller});

  String _label(Object? v) => knob.labelFor(v);

  @override
  Widget build(BuildContext context) {
    return KnobValueBuilder(
      controller: controller,
      id: knob.id,
      builder: (context, raw) {
        final value = knob.values.contains(raw) ? raw as T : knob.defaultValue;
        return Padding(
          key: ValueKey('wl.detail.knob.${knob.id}'),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            children: [
              Expanded(child: Text(knob.label)),
              DropdownButton<T>(
                key: ValueKey('wl.detail.knob.${knob.id}.control'),
                value: value,
                items: [
                  for (final v in knob.values)
                    DropdownMenuItem<T>(value: v, child: Text(_label(v))),
                ],
                onChanged: (v) {
                  if (v != null) controller.set(knob.id, v);
                },
              ),
              Offstage(
                child: Text(
                  _label(value),
                  key: ValueKey('wl.detail.knob.${knob.id}.value'),
                ),
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
