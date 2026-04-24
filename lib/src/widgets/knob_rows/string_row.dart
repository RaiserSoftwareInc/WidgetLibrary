import 'package:flutter/material.dart';

import '../../knobs/knob.dart';
import '../../knobs/knob_controller.dart';

class StringRow extends StatefulWidget {
  final StringKnob knob;
  final KnobController controller;

  const StringRow({super.key, required this.knob, required this.controller});

  @override
  State<StringRow> createState() => _StringRowState();
}

class _StringRowState extends State<StringRow> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.values[widget.knob.id]! as String,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
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
            onPressed: () {
              widget.controller.reset(widget.knob.id);
              _text.text = widget.knob.defaultValue;
            },
          ),
          Offstage(
            child: Text(
              _text.text,
              key: ValueKey('wl.detail.knob.${widget.knob.id}.value'),
            ),
          ),
        ],
      ),
    );
  }
}
