import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/knobs/knob_controller.dart';
import 'package:widget_library/src/widgets/knob_rows/knob_value_builder.dart';

void main() {
  testWidgets('KnobValueBuilder rebuilds only the builder for the changed id',
      (tester) async {
    final c = KnobController(const [
      IntKnob(id: 'a', label: 'A', defaultValue: 1, min: 0, max: 10),
      IntKnob(id: 'b', label: 'B', defaultValue: 2, min: 0, max: 10),
    ]);
    var buildsA = 0;
    var buildsB = 0;

    await tester.pumpWidget(
      Column(
        children: [
          KnobValueBuilder(
            controller: c,
            id: 'a',
            builder: (_, v) {
              buildsA++;
              return Text('a=$v', textDirection: TextDirection.ltr);
            },
          ),
          KnobValueBuilder(
            controller: c,
            id: 'b',
            builder: (_, v) {
              buildsB++;
              return Text('b=$v', textDirection: TextDirection.ltr);
            },
          ),
        ],
      ),
    );
    expect(buildsA, 1);
    expect(buildsB, 1);

    c.set('b', 5);
    await tester.pump();
    expect(buildsA, 1);
    expect(buildsB, 2);
    expect(find.text('b=5'), findsOneWidget);

    c.set('a', 7);
    await tester.pump();
    expect(buildsA, 2);
    expect(buildsB, 2);
    expect(find.text('a=7'), findsOneWidget);

    c.set('a', 7);
    await tester.pump();
    expect(buildsA, 2);
  });
}
