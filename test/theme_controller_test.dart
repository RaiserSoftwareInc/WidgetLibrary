import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('defaults to light and toggles between light and dark', () {
      final c = ThemeController();
      expect(c.value, ThemeMode.light);

      c.toggle();
      expect(c.value, ThemeMode.dark);

      c.toggle();
      expect(c.value, ThemeMode.light);
    });

    test('toggle normalizes ThemeMode.system to light', () {
      final c = ThemeController(initial: ThemeMode.system);
      c.toggle();
      expect(c.value, ThemeMode.light);
    });
  });

  group('CatalogTheme.of', () {
    testWidgets('returns the controller provided by the nearest ancestor',
        (tester) async {
      final controller = ThemeController();
      ThemeController? captured;

      await tester.pumpWidget(
        CatalogTheme(
          controller: controller,
          child: Builder(
            builder: (ctx) {
              captured = CatalogTheme.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, same(controller));
    });

    testWidgets('throws a clear error when no ancestor is found',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            expect(() => CatalogTheme.of(ctx), throwsFlutterError);
            return const SizedBox();
          },
        ),
      );
    });
  });
}
