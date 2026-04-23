import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/models/catalog_entry.dart';

void main() {
  group('CatalogEntry', () {
    test('stores name, states, and preserves insertion order', () {
      final entry = CatalogEntry(
        name: 'Button',
        states: {
          'default': (_) => const SizedBox(),
          'disabled': (_) => const SizedBox(),
        },
      );

      expect(entry.name, 'Button');
      expect(entry.states.keys.toList(), ['default', 'disabled']);
      expect(entry.category, isNull);
      expect(entry.thumbnail, isNull);
    });

    test('accepts optional category and thumbnail', () {
      final entry = CatalogEntry(
        name: 'Chip',
        category: 'Inputs',
        thumbnail: const Icon(IconData(0xe000)),
        states: {'default': (_) => const SizedBox()},
      );

      expect(entry.category, 'Inputs');
      expect(entry.thumbnail, isA<Icon>());
    });

    test('asserts when states map is empty in debug builds', () {
      expect(
        () => CatalogEntry(name: 'Empty', states: const {}),
        throwsAssertionError,
      );
    });
  });
}
