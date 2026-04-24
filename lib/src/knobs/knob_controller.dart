import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'knob.dart';
import 'knob_values.dart';

class KnobController extends ChangeNotifier {
  final Map<String, Object?> _values = {};
  List<Knob> _knobs;

  KnobController(List<Knob> knobs) : _knobs = List.unmodifiable(knobs) {
    for (final k in _knobs) {
      _values[k.id] = k.defaultValue;
    }
  }

  List<Knob> get knobs => _knobs;
  Map<String, Object?> get values => Map.unmodifiable(_values);
  KnobValues get readOnly => KnobValues(_values);

  void set(String id, Object? value) {
    final knob = _knobs.firstWhere(
      (k) => k.id == id,
      orElse: () => throw StateError('KnobController: unknown knob id "$id"'),
    );
    if (value == null || !_isCompatible(knob, value)) {
      throw ArgumentError.value(
        value,
        'value',
        'incompatible with ${knob.runtimeType} for id "$id"',
      );
    }
    _values[id] = value;
    notifyListeners();
  }

  void reset(String id) {
    final knob = _knobs.firstWhere(
      (k) => k.id == id,
      orElse: () => throw StateError('KnobController: unknown knob id "$id"'),
    );
    _values[id] = knob.defaultValue;
    notifyListeners();
  }

  void resetAll() {
    for (final k in _knobs) {
      _values[k.id] = k.defaultValue;
    }
    notifyListeners();
  }

  void reconcile(List<Knob> next) {
    final nextById = {for (final k in next) k.id: k};

    // Type-compat guard.
    for (final k in next) {
      final existing = _values[k.id];
      if (existing != null && !_isCompatible(k, existing)) {
        throw StateError(
          'KnobController.reconcile: id "${k.id}" changed type; '
          'existing value $existing is incompatible with ${k.runtimeType}',
        );
      }
    }

    // Drop removed.
    _values.removeWhere((id, _) => !nextById.containsKey(id));

    // Seed new.
    for (final k in next) {
      if (!_values.containsKey(k.id)) {
        _values[k.id] = k.defaultValue;
      }
    }

    _knobs = List.unmodifiable(next);
    notifyListeners();
  }

  static bool _isCompatible(Knob knob, Object value) {
    return switch (knob) {
      DoubleKnob() => value is double,
      IntKnob() => value is int,
      BoolKnob() => value is bool,
      StringKnob() => value is String,
      ColorKnob() => value is Color,
      EnumKnob(values: final opts) => opts.contains(value),
    };
  }
}
