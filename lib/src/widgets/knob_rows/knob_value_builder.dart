import 'package:flutter/widgets.dart';

import '../../knobs/knob_controller.dart';

/// Rebuilds [builder] only when `controller.values[id]` changes.
class KnobValueBuilder extends StatefulWidget {
  final KnobController controller;
  final String id;
  final Widget Function(BuildContext context, Object? value) builder;

  const KnobValueBuilder({
    super.key,
    required this.controller,
    required this.id,
    required this.builder,
  });

  @override
  State<KnobValueBuilder> createState() => _KnobValueBuilderState();
}

class _KnobValueBuilderState extends State<KnobValueBuilder> {
  Object? _rendered;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(KnobValueBuilder old) {
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

  void _onChange() {
    if (widget.controller.values[widget.id] == _rendered) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _rendered = widget.controller.values[widget.id];
    return widget.builder(context, _rendered);
  }
}
