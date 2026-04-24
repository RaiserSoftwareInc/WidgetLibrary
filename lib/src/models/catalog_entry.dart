import 'package:flutter/widgets.dart';

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

  CatalogEntry({
    required this.name,
    required Map<String, WidgetBuilder> states,
    this.category,
    this.thumbnail,
    this.previewSize = const Size(390, 844),
  })  : assert(states.isNotEmpty, 'CatalogEntry.states must not be empty'),
        states = Map.unmodifiable(states);
}
