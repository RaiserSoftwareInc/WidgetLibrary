import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/screens/detail_screen.dart';

CatalogEntry _entry(String name, {String? category}) => CatalogEntry(
      name: name,
      category: category,
      states: {'default': (_) => Text('preview:$name')},
    );

void main() {
  testWidgets('shows empty state with sample code when entries list is empty',
      (tester) async {
    await tester.pumpWidget(const CatalogApp(entries: []));
    expect(find.text('No widgets registered'), findsOneWidget);
    expect(find.textContaining('CatalogApp'), findsWidgets);
  });

  testWidgets('renders one tile per entry with name and state count badge',
      (tester) async {
    await tester.pumpWidget(CatalogApp(
      entries: [
        _entry('Button'),
        CatalogEntry(
          name: 'Card',
          states: {
            'default': (_) => const Text('a'),
            'elevated': (_) => const Text('b'),
          },
        ),
      ],
    ),);
    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('persistent search bar filters tiles by substring',
      (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button'), _entry('Card')]),
    );

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, 'but');
    await tester.pump();

    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsNothing);
  });

  testWidgets('shows no-match message when search has no results',
      (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button')]),
    );
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('No matches'), findsOneWidget);
  });

  testWidgets(
      'category chip strip appears only when entries provide categories',
      (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button')]),
    );
    expect(find.byType(FilterChip), findsNothing);

    await tester.pumpWidget(
      CatalogApp(
        entries: [
          _entry('Button', category: 'Inputs'),
          _entry('Card', category: 'Surfaces'),
        ],
      ),
    );
    expect(find.byType(FilterChip), findsWidgets);
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Inputs'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Surfaces'), findsOneWidget);
  });

  testWidgets('selecting a category filters the grid', (tester) async {
    await tester.pumpWidget(
      CatalogApp(
        entries: [
          _entry('Button', category: 'Inputs'),
          _entry('Card', category: 'Surfaces'),
        ],
      ),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Inputs'));
    await tester.pumpAndSettle();
    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsNothing);
  });

  testWidgets('tapping tile pushes DetailScreen', (tester) async {
    await tester.pumpWidget(CatalogApp(entries: [_entry('Button')]));
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('theme toggle flips MaterialApp.themeMode', (tester) async {
    await tester.pumpWidget(CatalogApp(entries: [_entry('Button')]));
    final before =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(before, ThemeMode.light);

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(after, ThemeMode.dark);
  });
}
