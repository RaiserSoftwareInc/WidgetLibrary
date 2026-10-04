import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';

Future<void> _openDetailAndSpecs(WidgetTester tester, CatalogEntry entry) async {
  await tester.pumpWidget(CatalogApp(entriesBuilder: () => [entry]));
  await tester.tap(find.text(entry.name));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Specs'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Specs action in detail AppBar opens a bottom sheet with sections',
      (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const SizedBox(width: 120, height: 40),
    },);

    await _openDetailAndSpecs(tester, entry);

    expect(find.text('Specs'), findsWidgets);
    expect(find.text('SIZE'), findsOneWidget);
    expect(find.text('THEME TOKENS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('WIDGET TREE'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('WIDGET TREE'), findsOneWidget);
  });

  testWidgets('Specs panel reports the laid-out size of the preview',
      (tester) async {
    final entry = CatalogEntry(name: 'Box', states: {
      'default': (_) => const SizedBox(width: 123, height: 45),
    },);

    await _openDetailAndSpecs(tester, entry);

    expect(find.textContaining('123.0 × 45.0'), findsOneWidget);
  });

  testWidgets('Specs panel includes primary color from theme', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('x'),
    },);

    await tester.pumpWidget(
      CatalogApp(
        entriesBuilder: () => [entry],
        lightTheme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(primary: Color(0xFF123456)),
        ),
      ),
    );
    await tester.tap(find.text(entry.name));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Specs'));
    await tester.pumpAndSettle();

    expect(find.text('#123456'), findsOneWidget);
  });

  testWidgets('Specs sections do not rebuild while the sheet is dragged',
      (tester) async {
    final entry = CatalogEntry(name: 'Box', states: {
      'default': (_) => const SizedBox(width: 123, height: 45),
    },);

    await _openDetailAndSpecs(tester, entry);

    final sizeRow = find.byWidgetPredicate(
      (w) => w is SelectableText && (w.data ?? '').contains('123.0 × 45.0'),
    );
    final sheet = find.byType(ListView).last;
    final title = find.text('Specs').last;
    final sizeBefore = tester.widget(sizeRow);
    final titleTopBefore = tester.getTopLeft(title);

    // Dragging the sheet content changes its extent, which makes
    // DraggableScrollableSheet re-invoke its builder on every frame.
    await tester.drag(sheet, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(title), isNot(titleTopBefore));

    final treeLine = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').contains('KeyedSubtree'),
    );
    final treeBefore = tester.widget(treeLine);

    await tester.drag(sheet, const Offset(0, 100));
    await tester.pumpAndSettle();

    expect(identical(sizeBefore, tester.widget(sizeRow)), isTrue);
    expect(identical(treeBefore, tester.widget(treeLine)), isTrue);
  });
}
