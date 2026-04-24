import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';

CatalogEntry _reproEntry() => CatalogEntry(
      name: 'Repro',
      states: {
        'default': (_) => Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFF0000),
            ),
      },
    );

void main() {
  testWidgets(
      'grid tile renders fill-width widget without infinite-constraint assertion',
      (tester) async {
    await tester.pumpWidget(CatalogApp(entriesBuilder: () => [_reproEntry()]));
    expect(tester.takeException(), isNull);
    expect(find.text('Repro'), findsOneWidget);
  });

  testWidgets(
      'detail screen renders fill-width widget and reports non-zero size',
      (tester) async {
    await tester.pumpWidget(CatalogApp(entriesBuilder: () => [_reproEntry()]));
    await tester.tap(find.text('Repro'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Render the preview and confirm it occupies space.
    final redFinder = find.byWidgetPredicate(
      (w) => w is Container &&
          (w.color == const Color(0xFFFF0000) ||
              ((w.decoration as BoxDecoration?)?.color ==
                  const Color(0xFFFF0000))),
    );
    expect(redFinder, findsOneWidget);
    final size = tester.getSize(redFinder);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
  });

  testWidgets(
      'detail screen renders Stack(fit: expand) without infinite-constraint assertion',
      (tester) async {
    final entry = CatalogEntry(name: 'StackExpand', states: {
      'default': (_) => const Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Color(0xFF00FF00)),
            ],
          ),
    },);
    await tester.pumpWidget(CatalogApp(entriesBuilder: () => [entry]));
    await tester.tap(find.text('StackExpand'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom previewSize overrides the default 390x844 viewport',
      (tester) async {
    final entry = CatalogEntry(
      name: 'SmallFrame',
      previewSize: const Size(120, 80),
      states: {
        'default': (_) => Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0000FF),
            ),
      },
    );
    await tester.pumpWidget(CatalogApp(entriesBuilder: () => [entry]));
    await tester.tap(find.text('SmallFrame'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
