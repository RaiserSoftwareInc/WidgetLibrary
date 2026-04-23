import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/screens/detail_screen.dart';

Widget _host(CatalogEntry entry) => CatalogApp(entries: [entry]);

Future<void> _openDetail(WidgetTester tester, CatalogEntry entry) async {
  await tester.pumpWidget(_host(entry));
  await tester.tap(find.text(entry.name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders first state initially', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
      'disabled': (_) => const Text('STATE-disabled'),
    },);
    await _openDetail(tester, entry);
    expect(find.text('STATE-default'), findsOneWidget);
    expect(find.text('STATE-disabled'), findsNothing);
  });

  testWidgets('tapping a chip swaps the rendered preview', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
      'disabled': (_) => const Text('STATE-disabled'),
    },);
    await _openDetail(tester, entry);

    await tester.tap(find.widgetWithText(ChoiceChip, 'disabled'));
    await tester.pumpAndSettle();

    expect(find.text('STATE-disabled'), findsOneWidget);
    expect(find.text('STATE-default'), findsNothing);
  });

  testWidgets('throwing builder is caught by ErrorBoundary', (tester) async {
    final entry = CatalogEntry(name: 'Bad', states: {
      'default': (_) => throw StateError('kaboom'),
    },);
    await _openDetail(tester, entry);
    expect(find.textContaining('kaboom'), findsOneWidget);
  });

  testWidgets('theme toggle in detail app bar flips theme mode', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
    },);
    await _openDetail(tester, entry);

    final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(before, ThemeMode.light);

    await tester.tap(find.descendant(
      of: find.byType(DetailScreen),
      matching: find.byTooltip('Toggle theme'),
    ),);
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(after, ThemeMode.dark);
  });
}
