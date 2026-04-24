import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';

void main() {
  group('KnobController', () {
    const height = DoubleKnob(
      id: 'height',
      label: 'Height',
      defaultValue: 220,
      min: 100,
      max: 400,
    );
    const enabled = BoolKnob(
      id: 'enabled',
      label: 'Enabled',
      defaultValue: true,
    );

    test('seeds defaults on construction', () {
      final c = KnobController([height, enabled]);
      expect(c.values['height'], 220.0);
      expect(c.values['enabled'], true);
    });

    test('set writes value and notifies', () {
      final c = KnobController([height]);
      var n = 0;
      c.addListener(() => n++);
      c.set('height', 300.0);
      expect(c.values['height'], 300.0);
      expect(n, 1);
    });

    test('reset restores default', () {
      final c = KnobController([height]);
      c.set('height', 300.0);
      c.reset('height');
      expect(c.values['height'], 220.0);
    });

    test('resetAll restores every default', () {
      final c = KnobController([height, enabled]);
      c.set('height', 300.0);
      c.set('enabled', false);
      c.resetAll();
      expect(c.values['height'], 220.0);
      expect(c.values['enabled'], true);
    });

    test('set on unknown id throws StateError', () {
      final c = KnobController([height]);
      expect(() => c.set('ghost', 1), throwsStateError);
    });

    test('reconcile preserves matching-id user value', () {
      final c = KnobController([height]);
      c.set('height', 320.0);

      const heightUpdatedDefault = DoubleKnob(
        id: 'height',
        label: 'Height',
        defaultValue: 260, // changed default
        min: 100,
        max: 400,
      );
      c.reconcile([heightUpdatedDefault]);

      expect(c.values['height'], 320.0); // user value kept
    });

    test('reconcile drops removed ids and seeds new ones', () {
      final c = KnobController([height]);
      c.set('height', 300.0);
      c.reconcile([enabled]);

      expect(c.values.containsKey('height'), false);
      expect(c.values['enabled'], true);
    });

    test('reconcile rejects id reuse across incompatible types', () {
      final c = KnobController([height]);
      const stringHeight = StringKnob(
        id: 'height',
        label: 'Height',
        defaultValue: 'tall',
      );
      expect(() => c.reconcile([stringHeight]), throwsStateError);
    });

    test('set with wrong-typed value throws ArgumentError', () {
      final c = KnobController([height]);
      expect(() => c.set('height', 'oops'), throwsArgumentError);
      expect(c.values['height'], 220.0); // value unchanged
    });

    test('set with null throws ArgumentError', () {
      final c = KnobController([height]);
      expect(() => c.set('height', null), throwsArgumentError);
      expect(c.values['height'], 220.0);
    });

    test('reconcile notifies listeners', () {
      final c = KnobController([height]);
      var n = 0;
      c.addListener(() => n++);
      c.reconcile([height, enabled]);
      expect(n, 1);
    });
  });
}
