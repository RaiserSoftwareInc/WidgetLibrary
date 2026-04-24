import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';
import 'package:widget_library/src/widgets/knob_rows/string_row.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('StringRow syncs TextField when controller changes externally',
      (tester) async {
    const knob = StringKnob(
      id: 'label',
      label: 'Label',
      defaultValue: 'Tap me',
    );
    final controller = KnobController([knob]);

    await _pump(
      tester,
      StringRow(knob: knob, controller: controller),
    );

    // Initial text matches default.
    expect(find.text('Tap me'), findsOneWidget);

    // External mutation (not through the TextField).
    controller.set('label', 'Submit');
    await tester.pump();

    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('Tap me'), findsNothing);
  });

  testWidgets('StringRow reset button restores default via controller',
      (tester) async {
    const knob = StringKnob(
      id: 'label',
      label: 'Label',
      defaultValue: 'Tap me',
    );
    final controller = KnobController([knob]);

    await _pump(
      tester,
      StringRow(knob: knob, controller: controller),
    );

    controller.set('label', 'Changed');
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('wl.detail.knob.label.reset')),
    );
    await tester.pump();

    expect(find.text('Tap me'), findsOneWidget);
    expect(controller.values['label'], 'Tap me');
  });
}
