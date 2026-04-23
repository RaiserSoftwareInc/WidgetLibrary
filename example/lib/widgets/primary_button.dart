import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled && !loading ? () {} : null,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
