import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';
import 'knob_value_builder.dart';

class StringRow extends StatefulWidget {
  final StringKnob knob;
  final KnobController controller;

  const StringRow({super.key, required this.knob, required this.controller});

  @override
  State<StringRow> createState() => _StringRowState();
}

class _StringRowState extends State<StringRow> {
  late final TextEditingController _text = TextEditingController(
    text: _currentModelValue(),
  );

  String _currentModelValue() =>
      widget.controller.values[widget.knob.id]! as String;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromModel);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromModel);
    _text.dispose();
    super.dispose();
  }

  void _syncFromModel() {
    final modelValue = _currentModelValue();
    if (_text.text == modelValue) return;
    // External change: reflect it without disturbing the user's cursor more
    // than necessary. If the field still had focus, we place the caret at the
    // end of the new value.
    _text.value = TextEditingValue(
      text: modelValue,
      selection: TextSelection.collapsed(offset: modelValue.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('wl.detail.knob.${widget.knob.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(widget.knob.label)),
          Expanded(
            child: TextField(
              key: ValueKey('wl.detail.knob.${widget.knob.id}.control'),
              controller: _text,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.knob.hint,
              ),
              onChanged: (v) => widget.controller.set(widget.knob.id, v),
            ),
          ),
          IconButton(
            key: ValueKey('wl.detail.knob.${widget.knob.id}.reset'),
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: () => widget.controller.reset(widget.knob.id),
          ),
          Offstage(
            child: KnobValueBuilder(
              controller: widget.controller,
              id: widget.knob.id,
              builder: (_, value) => Text(
                value! as String,
                key: ValueKey('wl.detail.knob.${widget.knob.id}.value'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
