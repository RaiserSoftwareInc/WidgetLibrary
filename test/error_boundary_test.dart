import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_library/src/widgets/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when builder succeeds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(builder: (_) => const Text('ok')),
        ),
      );
      expect(find.text('ok'), findsOneWidget);
    });

    testWidgets('shows error text when builder throws', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            builder: (_) => throw StateError('boom'),
          ),
        ),
      );
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });
}
