import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';

class DetailScreen extends StatelessWidget {
  final CatalogEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: const SizedBox.shrink(),
    );
  }
}
