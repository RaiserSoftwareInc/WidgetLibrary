import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class EnumRow<T> extends StatelessWidget {
  final EnumKnob<T> knob;
  final KnobController controller;

  const EnumRow({super.key, required this.knob, required this.controller});

  String _label(T v) => knob.labelOf?.call(v) ?? '$v';

  @override
  Widget build(BuildContext context) {
    final value = controller.values[knob.id] as T;

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
  }
}
