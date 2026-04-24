import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';

void main() {
  group('CatalogEntry.live', () {
    test('stores knobs and builder; isLive is true', () {
      final entry = CatalogEntry.live(
        name: 'Header',
        knobs: const [
          DoubleKnob(
            id: 'h',
            label: 'Height',
            defaultValue: 220,
            min: 100,
            max: 400,
          ),
        ],
        builder: (ctx, v) => SizedBox(height: v.getDouble('h')),
      );

      expect(entry.isLive, true);
      expect(entry.knobs, isNotNull);
      expect(entry.knobs!.first.id, 'h');
      expect(entry.builder, isNotNull);
    });

    test('synthesizes single default state keyed "live"', () {
      final entry = CatalogEntry.live(
        name: 'Header',
        knobs: const [
          DoubleKnob(
            id: 'h',
            label: 'Height',
            defaultValue: 220,
            min: 100,
            max: 400,
          ),
        ],
        builder: (ctx, v) => SizedBox(height: v.getDouble('h')),
      );

      expect(entry.states.keys.toList(), ['live']);
    });

    test('legacy constructor still has null knobs and builder', () {
      final entry = CatalogEntry(
        name: 'Button',
        states: {'default': (_) => const SizedBox()},
      );

      expect(entry.isLive, false);
      expect(entry.knobs, isNull);
      expect(entry.builder, isNull);
    });

    test('asserts when knobs is empty', () {
      expect(
        () => CatalogEntry.live(
          name: 'Bad',
          knobs: const [],
          builder: (_, __) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
