import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'widgets/primary_button.dart';

List<CatalogEntry> buildCatalog() => [
      CatalogEntry(
        name: 'Primary Button',
        states: {
          'default': (_) => const PrimaryButton(label: 'Tap me'),
          'disabled': (_) => const PrimaryButton(label: 'Tap me', enabled: false),
          'loading': (_) => const PrimaryButton(label: 'Tap me', loading: true),
        },
      ),
      CatalogEntry(
        name: 'Chip',
        states: {
          'default': (_) => const Chip(label: Text('Tag')),
          'with-avatar': (_) => const Chip(
                avatar: CircleAvatar(child: Text('A')),
                label: Text('Tag'),
              ),
        },
      ),
    ];
