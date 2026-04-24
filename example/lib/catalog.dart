import 'package:flutter/material.dart';
import 'package:widget_library/widget_library.dart';

import 'widgets/primary_button.dart';

List<CatalogEntry> buildCatalog() => [
      CatalogEntry.live(
        name: 'Primary Button',
        category: 'Buttons',
        knobs: const [
          StringKnob(id: 'label', label: 'Label', defaultValue: 'Tap me'),
          BoolKnob(id: 'enabled', label: 'Enabled', defaultValue: true),
          BoolKnob(id: 'loading', label: 'Loading', defaultValue: false),
        ],
        builder: (ctx, v) => PrimaryButton(
          label: v.getString('label'),
          enabled: v.getBool('enabled'),
          loading: v.getBool('loading'),
        ),
      ),
      CatalogEntry(
        name: 'Chip',
        category: 'Inputs',
        states: {
          'default': (_) => const Chip(label: Text('Tag')),
          'with-avatar': (_) => const Chip(
                avatar: CircleAvatar(child: Text('A')),
                label: Text('Tag'),
              ),
        },
      ),
    ];
