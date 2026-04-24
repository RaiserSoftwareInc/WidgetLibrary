import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';
import 'package:widget_library/src/screens/detail_screen.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

enum _Variant { a, b, c }

Widget _wrap(Widget child) {
  final controller = ThemeController(initial: ThemeMode.light);
  return CatalogTheme(
    controller: controller,
    child: MaterialApp(home: child),
  );
}

void main() {
  test('EnumKnob const constructor works (no non-const length assert)', () {
    const knob = EnumKnob<_Variant>(
      id: 'v',
      label: 'Variant',
      defaultValue: _Variant.a,
      values: [_Variant.a, _Variant.b, _Variant.c],
    );
    expect(knob.values.length, 3);
  });

  test('EnumKnob.labelFor invokes typed labelOf without subtype error', () {
    final knob = EnumKnob<_Variant>(
      id: 'v',
      label: 'Variant',
      defaultValue: _Variant.a,
      values: const [_Variant.a, _Variant.b, _Variant.c],
      labelOf: (v) => v.name.toUpperCase(),
    );

    // Call-site passes Object? — the regression scenario.
    final Object? raw = _Variant.b;
    expect(knob.labelFor(raw), 'B');
  });

  test('EnumKnob.labelFor falls back to toString when labelOf null', () {
    final knob = EnumKnob<_Variant>(
      id: 'v',
      label: 'Variant',
      defaultValue: _Variant.a,
      values: const [_Variant.a, _Variant.b],
    );
    expect(knob.labelFor(_Variant.a), '_Variant.a');
  });

  testWidgets('generic EnumKnob renders in detail screen without type error',
      (tester) async {
    final entry = CatalogEntry.live(
      name: 'X',
      knobs: [
        EnumKnob<_Variant>(
          id: 'v',
          label: 'Variant',
          defaultValue: _Variant.a,
          values: const [_Variant.a, _Variant.b, _Variant.c],
          labelOf: (v) => v.name,
        ),
      ],
      builder: (ctx, k) => Text(k.getEnum<_Variant>('v').name),
    );

    await tester.pumpWidget(
      _wrap(
        DetailScreen(
          entryName: 'X',
          entriesBuilder: () => [entry],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('wl.detail.knob.v')), findsOneWidget);
  });
}
