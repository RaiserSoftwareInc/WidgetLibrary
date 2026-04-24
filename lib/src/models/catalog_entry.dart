import 'package:flutter/widgets.dart';

import '../knobs/knob.dart';
import '../knobs/knob_values.dart';

@immutable
class CatalogEntry {
  final String name;
  final String? category;
  final Map<String, WidgetBuilder> states;
  final Widget? thumbnail;

  /// Virtual viewport given to the widget when rendered in the viewer. Any
  /// `double.infinity`, `Stack(fit: expand)`, or fill-width/height pattern
  /// resolves against these bounds instead of the screen or an infinite
  /// canvas. Defaults to a phone-like 390x844. Override per-entry for
  /// widgets with a different natural footprint.
  final Size previewSize;

  /// Live-mode knob declarations. `null` for legacy `states`-based entries.
  final List<Knob>? knobs;

  /// Live-mode builder. `null` for legacy entries.
  final Widget Function(BuildContext context, KnobValues values)? builder;

  CatalogEntry({
    required this.name,
    required Map<String, WidgetBuilder> states,
    this.category,
    this.thumbnail,
    this.previewSize = const Size(390, 844),
  })  : assert(states.isNotEmpty, 'CatalogEntry.states must not be empty'),
        states = Map.unmodifiable(states),
        knobs = null,
        builder = null;

  CatalogEntry.live({
    required this.name,
    required List<Knob> knobs,
    required Widget Function(BuildContext, KnobValues) builder,
    this.category,
    this.thumbnail,
    this.previewSize = const Size(390, 844),
  })  : assert(knobs.isNotEmpty, 'CatalogEntry.live: knobs must not be empty'),
        knobs = List.unmodifiable(knobs),
        // builder captured in _synthesizeLiveStates; can't use this.builder in init list
        builder = builder, // ignore: prefer_initializing_formals
        states = _synthesizeLiveStates(knobs, builder);

  static Map<String, WidgetBuilder> _synthesizeLiveStates(
    List<Knob> knobs,
    Widget Function(BuildContext, KnobValues) builder,
  ) {
    final defaults = KnobValues({
      for (final k in knobs) k.id: k.defaultValue,
    });
    return Map.unmodifiable({
      'live': (ctx) => builder(ctx, defaults),
    });
  }

  bool get isLive => knobs != null && builder != null;
}
