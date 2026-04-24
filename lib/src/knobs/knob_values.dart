import 'package:flutter/painting.dart';

import 'knob.dart';

class KnobValues {
  final Map<String, Object?> _values;

  const KnobValues(this._values);

  Object? _raw(String id) {
    if (!_values.containsKey(id)) {
      throw StateError('KnobValues: no value for id "$id"');
    }
    return _values[id];
  }

  double getDouble(String id) => _raw(id) as double;
  int getInt(String id) => _raw(id) as int;
  bool getBool(String id) => _raw(id) as bool;
  String getString(String id) => _raw(id) as String;
  Color getColor(String id) => _raw(id) as Color;
  T getEnum<T>(String id) => _raw(id) as T;

  T valueOf<T>(Knob<T> knob) => _raw(knob.id) as T;
}
