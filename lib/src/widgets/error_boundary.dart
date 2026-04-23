import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final WidgetBuilder builder;
  const ErrorBoundary({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context);
    } catch (error, stack) {
      return _ErrorView(error: error, stack: stack);
    }
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final StackTrace stack;
  const _ErrorView({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 1),
        color: Colors.red.withValues(alpha: 0.08),
      ),
      child: SingleChildScrollView(
        child: Text(
          'Widget build failed:\n$error\n\n$stack',
          style: TextStyle(
            color: Colors.red.shade900,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
