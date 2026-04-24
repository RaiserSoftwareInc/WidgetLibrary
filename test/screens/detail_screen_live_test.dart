import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';
import 'package:widget_library/src/screens/detail_screen.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

Widget _wrap(Widget child) {
  final controller = ThemeController(initial: ThemeMode.light);
  return CatalogTheme(
    controller: controller,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('live entry renders knob panel; slider drag rebuilds preview',
      (tester) async {
    final entry = CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 100,
          min: 50,
          max: 300,
        ),
      ],
      builder: (ctx, v) => Container(
        key: const ValueKey('probe'),
        width: 100,
        height: v.getDouble('h'),
        color: const Color(0xFF1E88E5),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        DetailScreen(
          entryName: 'Box',
          entriesBuilder: () => [entry],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('wl.detail.knob_panel')), findsOneWidget);

    Container probe() =>
        tester.widget<Container>(find.byKey(const ValueKey('probe')));

    expect(probe().constraints?.maxHeight, 100);

    await tester.drag(
      find.byKey(const ValueKey('wl.detail.knob.h.control')),
      const Offset(200, 0),
    );
    await tester.pump();

    expect(probe().constraints!.maxHeight, greaterThan(100));
  });

  testWidgets('legacy entry still renders variant picker', (tester) async {
    final entry = CatalogEntry(
      name: 'Btn',
      states: {
        'a': (_) => const Text('A'),
        'b': (_) => const Text('B'),
      },
    );

    await tester.pumpWidget(
      _wrap(
        DetailScreen(
          entryName: 'Btn',
          entriesBuilder: () => [entry],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('wl.detail.variant.a')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.variant.b')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.knob_panel')), findsNothing);
  });

  testWidgets('missing entry shows not-found placeholder', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DetailScreen(
          entryName: 'Ghost',
          entriesBuilder: () => const [],
        ),
      ),
    );

    expect(find.textContaining("'Ghost' not found"), findsOneWidget);
  });
}
