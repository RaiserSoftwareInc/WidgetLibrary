import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_values.dart';

void main() {
  group('KnobValues', () {
    test('typed getters return correctly typed values', () {
      const values = KnobValues({
        'height': 220.0,
        'count': 3,
        'enabled': true,
        'label': 'Tap me',
        'bg': Color(0xFF112233),
        'mode': 'dark',
      });

      expect(values.getDouble('height'), 220.0);
      expect(values.getInt('count'), 3);
      expect(values.getBool('enabled'), true);
      expect(values.getString('label'), 'Tap me');
      expect(values.getColor('bg'), const Color(0xFF112233));
      expect(values.getEnum<String>('mode'), 'dark');
    });

    test('valueOf reads by knob instance', () {
      const knob = DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 100,
        min: 0,
        max: 200,
      );
      const values = KnobValues({'h': 150.0});

      expect(values.valueOf(knob), 150.0);
    });

    test('missing id throws StateError', () {
      const values = KnobValues({});
      expect(() => values.getDouble('missing'), throwsStateError);
    });

    test('asserts on invalid DoubleKnob range', () {
      expect(
        () => DoubleKnob(
          id: 'x',
          label: 'X',
          defaultValue: 500,
          min: 0,
          max: 100,
        ),
        throwsAssertionError,
      );
    });
  });
}
