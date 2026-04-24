import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';

CatalogEntry _entry(String name, {String? category}) => CatalogEntry(
      name: name,
      category: category,
      states: {'default': (_) => Text('preview:$name')},
    );

void main() {
  testWidgets('grid surfaces expose stable Marionette keys', (tester) async {
    await tester.pumpWidget(CatalogApp(
      entries: () => [
        _entry('Button', category: 'Inputs'),
        _entry('Card', category: 'Surfaces'),
      ],
    ),);

    expect(find.byKey(const ValueKey('wl.search_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.app_bar.theme_toggle')),
        findsOneWidget,);
    expect(find.byKey(const ValueKey('wl.category_chip.All')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.category_chip.Inputs')),
        findsOneWidget,);
    expect(find.byKey(const ValueKey('wl.grid_tile.Button')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.grid_tile.Card')), findsOneWidget);
  });

  testWidgets('detail surfaces expose stable Marionette keys', (tester) async {
    final entry = CatalogEntry(name: 'Button', states: {
      'default': (_) => const Text('STATE-default'),
      'disabled': (_) => const Text('STATE-disabled'),
    },);
    await tester.pumpWidget(CatalogApp(entries: () => [entry]));
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wl.app_bar.specs')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.app_bar.theme_toggle')),
        findsOneWidget,);
    expect(find.byKey(const ValueKey('wl.detail.variant.default')),
        findsOneWidget,);
    expect(find.byKey(const ValueKey('wl.detail.variant.disabled')),
        findsOneWidget,);
  });

  testWidgets('empty state exposes copy key', (tester) async {
    await tester.pumpWidget(CatalogApp(entries: () => const []));
    expect(find.byKey(const ValueKey('wl.empty_state.copy')), findsOneWidget);
  });
}
