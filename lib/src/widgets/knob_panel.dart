import 'package:flutter/material.dart';

import '../knobs/knob.dart';
import '../knobs/knob_controller.dart';
import 'knob_rows/bool_row.dart';
import 'knob_rows/color_row.dart';
import 'knob_rows/double_row.dart';
import 'knob_rows/enum_row.dart';
import 'knob_rows/int_row.dart';
import 'knob_rows/knob_value_builder.dart';
import 'knob_rows/string_row.dart';

class KnobPanel extends StatefulWidget {
  final KnobController controller;

  const KnobPanel({super.key, required this.controller});

  @override
  State<KnobPanel> createState() => _KnobPanelState();
}

class _KnobPanelState extends State<KnobPanel> {
  List<Knob>? _rendered;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(KnobPanel old) {
    super.didUpdateWidget(old);
    if (identical(old.controller, widget.controller)) return;
    old.controller.removeListener(_onChange);
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  // Rows listen for their own value; the panel only tracks the knob list.
  void _onChange() {
    if (identical(_rendered, widget.controller.knobs)) return;
    setState(() {});
  }

  // Each row rebuilds only when its own value changes.
  Widget _rowFor(Knob knob) {
    final controller = widget.controller;
    return KnobValueBuilder(
      controller: controller,
      id: knob.id,
      builder: (_, __) => switch (knob) {
        DoubleKnob() => DoubleRow(knob: knob, controller: controller),
        IntKnob() => IntRow(knob: knob, controller: controller),
        BoolKnob() => BoolRow(knob: knob, controller: controller),
        StringKnob() => StringRow(knob: knob, controller: controller),
        ColorKnob() => ColorRow(knob: knob, controller: controller),
        EnumKnob<dynamic>() => EnumRow<dynamic>(
            knob: knob,
            controller: controller,
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final knobs = _rendered = widget.controller.knobs;
    return Material(
      key: const ValueKey('wl.detail.knob_panel'),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Knobs',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton.icon(
                  key: const ValueKey('wl.detail.knobs.reset_all'),
                  onPressed: widget.controller.resetAll,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: knobs.length,
              itemBuilder: (ctx, i) => _rowFor(knobs[i]),
            ),
          ),
        ],
      ),
    );
  }
}
