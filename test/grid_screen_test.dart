import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/screens/detail_screen.dart';

CatalogEntry _entry(String name) => CatalogEntry(
      name: name,
      states: {'default': (_) => Text('preview:$name')},
    );

void main() {
  testWidgets('shows empty state when entries list is empty', (tester) async {
    await tester.pumpWidget(const CatalogApp(entries: []));
    expect(find.text('No widgets registered'), findsOneWidget);
  });

  testWidgets('renders one tile per entry with name visible', (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button'), _entry('Card')]),
    );
    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
  });

  testWidgets('search filters tiles by case-insensitive substring',
      (tester) async {
    await tester.pumpWidget(
      CatalogApp(entries: [_entry('Button'), _entry('Card')]),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'but');
    await tester.pump();

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
    final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(before, ThemeMode.light);

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(after, ThemeMode.dark);
  });
}
