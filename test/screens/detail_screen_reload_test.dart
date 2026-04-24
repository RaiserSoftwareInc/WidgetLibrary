import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/knobs/knob.dart';
import 'package:widget_library/src/models/catalog_entry.dart';
import 'package:widget_library/src/screens/detail_screen.dart';
import 'package:widget_library/src/theme/theme_controller.dart';

Widget _wrap(Widget child) {
  final controller = ThemeController(initial: ThemeMode.light);
  return CatalogTheme(
    controller: controller,
    child: MaterialApp(home: child),
  );
}

CatalogEntry _v1() => CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 100,
          min: 50,
          max: 300,
        ),
        BoolKnob(id: 'on', label: 'Enabled', defaultValue: true),
      ],
      builder: (ctx, v) => SizedBox(
        key: const ValueKey('probe'),
        height: v.getDouble('h'),
      ),
    );

CatalogEntry _v2() => CatalogEntry.live(
      name: 'Box',
      knobs: const [
        DoubleKnob(
          id: 'h',
          label: 'Height',
          defaultValue: 250, // changed default
          min: 50,
          max: 300,
        ),
        // 'on' removed
        StringKnob(id: 'label', label: 'Label', defaultValue: 'hello'),
      ],
      builder: (ctx, v) => SizedBox(
        key: const ValueKey('probe'),
        height: v.getDouble('h'),
      ),
    );

void main() {
  testWidgets('reassemble reconciles knobs and preserves user values',
      (tester) async {
    var version = 1;
    List<CatalogEntry> builder() => [version == 1 ? _v1() : _v2()];

    final screen = DetailScreen(
      entryName: 'Box',
      entriesBuilder: builder,
    );
    await tester.pumpWidget(_wrap(screen));

    // User drags height to a new value (Slider drag).
    await tester.drag(
      find.byKey(const ValueKey('wl.detail.knob.h.control')),
      const Offset(200, 0),
    );
    await tester.pump();

    SizedBox probe() =>
        tester.widget<SizedBox>(find.byKey(const ValueKey('probe')));
    final userHeight = probe().height!;
    expect(userHeight, greaterThan(100));

    // Swap entry version and fire reassemble.
    // reassembleApplication() schedules work on the microtask queue;
    // do not await it — pump() drives the fake-async loop to completion.
    version = 2;
    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    await tester.pump();

    // Old 'on' knob removed.
    expect(find.byKey(const ValueKey('wl.detail.knob.on')), findsNothing);
    // New 'label' knob appears.
    expect(find.byKey(const ValueKey('wl.detail.knob.label')), findsOneWidget);
    // Matching 'h' preserves user value (default change does not overwrite).
    expect(probe().height, userHeight);
  });
}
