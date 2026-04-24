import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';
import 'package:widget_library/src/widgets/knob_panel.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one row per knob in order', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
      BoolKnob(id: 'on', label: 'Enabled', defaultValue: true),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    expect(find.byKey(const ValueKey('wl.detail.knob.h')), findsOneWidget);
    expect(find.byKey(const ValueKey('wl.detail.knob.on')), findsOneWidget);
  });

  testWidgets('updates readback label on controller.set', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    final readback = find.byKey(const ValueKey('wl.detail.knob.h.value'));
    expect((tester.widget(readback) as Text).data, '200.0');

    c.set('h', 300.0);
    await tester.pump();

    expect((tester.widget(readback) as Text).data, '300.0');
  });

  testWidgets('reset all restores every default', (tester) async {
    final c = KnobController(const [
      DoubleKnob(
        id: 'h',
        label: 'Height',
        defaultValue: 200,
        min: 100,
        max: 400,
      ),
    ]);
    await _pump(tester, KnobPanel(controller: c));

    c.set('h', 300.0);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('wl.detail.knobs.reset_all')));
    await tester.pump();

    expect(c.values['h'], 200.0);
  });
}
