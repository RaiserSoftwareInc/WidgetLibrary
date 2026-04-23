import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({ThemeMode initial = ThemeMode.light}) : super(initial);

  void toggle() {
    if (value == ThemeMode.system) {
      value = ThemeMode.light;
      return;
    }
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class CatalogTheme extends InheritedNotifier<ThemeController> {
  const CatalogTheme({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<CatalogTheme>();
    if (widget == null) {
      throw FlutterError(
        'CatalogTheme.of() called with a context that does not contain a CatalogTheme.',
      );
    }
    return widget.notifier!;
  }
}
