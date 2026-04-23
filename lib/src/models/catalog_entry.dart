import 'package:flutter/widgets.dart';

@immutable
class CatalogEntry {
  final String name;
  final String? category;
  final Map<String, WidgetBuilder> states;
  final Widget? thumbnail;

  CatalogEntry({
    required this.name,
    required Map<String, WidgetBuilder> states,
    this.category,
    this.thumbnail,
  })  : assert(states.isNotEmpty, 'CatalogEntry.states must not be empty'),
        states = Map.unmodifiable(states);
}
