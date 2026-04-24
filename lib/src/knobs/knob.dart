import 'package:flutter/painting.dart';

sealed class Knob<T> {
  final String id;
  final String label;
  final T defaultValue;

  const Knob({
    required this.id,
    required this.label,
    required this.defaultValue,
  });
}

class DoubleKnob extends Knob<double> {
  final double min;
  final double max;
  final double? step;

  const DoubleKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.min,
    required this.max,
    this.step,
  })  : assert(min < max, 'DoubleKnob.min must be < max'),
        assert(
          defaultValue >= min && defaultValue <= max,
          'DoubleKnob.defaultValue must be within [min, max]',
        );
}

class IntKnob extends Knob<int> {
  final int min;
  final int max;
  final int step;

  const IntKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.min,
    required this.max,
    this.step = 1,
  })  : assert(min < max, 'IntKnob.min must be < max'),
        assert(step > 0, 'IntKnob.step must be > 0'),
        assert(
          defaultValue >= min && defaultValue <= max,
          'IntKnob.defaultValue must be within [min, max]',
        );
}

class BoolKnob extends Knob<bool> {
  const BoolKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
  });
}

class StringKnob extends Knob<String> {
  final String? hint;

  const StringKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    this.hint,
  });
}

class EnumKnob<T> extends Knob<T> {
  final List<T> values;
  final String Function(T value)? labelOf;

  const EnumKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    required this.values,
    this.labelOf,
  });

  String labelFor(Object? value) =>
      labelOf == null ? '$value' : labelOf!(value as T);
}

class ColorKnob extends Knob<Color> {
  final List<Color>? swatches;

  const ColorKnob({
    required super.id,
    required super.label,
    required super.defaultValue,
    this.swatches,
  });
}
