import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/widget_library.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

List<CatalogEntry> _empty() => const [];

void main() {
  testWidgets('CatalogApp builds with empty entries and exposes CatalogTheme',
      (tester) async {
    await tester.pumpWidget(
      const CatalogApp(entries: _empty),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('CatalogApp.themeMode tracks the ThemeController', (tester) async {
    await tester.pumpWidget(const CatalogApp(entries: _empty));
    final materialApp1 = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp1.themeMode, ThemeMode.light);

    final ctx = tester.element(find.byType(MaterialApp));
    CatalogTheme.of(ctx).toggle();
    await tester.pump();

    final materialApp2 = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp2.themeMode, ThemeMode.dark);
  });

  testWidgets('CatalogApp honors explicit initialTheme', (tester) async {
    await tester.pumpWidget(
      const CatalogApp(entries: _empty, initialTheme: ThemeMode.dark),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('CatalogApp default initialTheme follows platform brightness',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const CatalogApp(entries: _empty));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('CatalogApp passes through lightTheme and darkTheme', (tester) async {
    final light = ThemeData(primarySwatch: Colors.blue);
    final dark = ThemeData.dark();

    await tester.pumpWidget(
      CatalogApp(entries: _empty, lightTheme: light, darkTheme: dark),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, same(light));
    expect(app.darkTheme, same(dark));
  });
}
