import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'catalog.dart';

void main() {
  runApp(CatalogApp(
    entriesBuilder: buildCatalog,
    lightTheme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
  ));
}
