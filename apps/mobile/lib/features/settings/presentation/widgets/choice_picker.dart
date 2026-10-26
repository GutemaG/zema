import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';

/// Opens a sheet with one radio option per entry of [options] (value and
/// label), [current] selected. Returns the picked value, or null when
/// dismissed. An optional [note] shows under the options.
Future<T?> showChoicePicker<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T current,
  String? note,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            RadioGroup<T>(
              groupValue: current,
              // Tapping the selected option reports null; it still closes.
              onChanged: (value) => Navigator.of(context).pop(value ?? current),
              child: Column(
                children: [
                  for (final (value, label) in options)
                    RadioListTile<T>(
                      value: value,
                      toggleable: true,
                      title: Text(label),
                    ),
                ],
              ),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text(
                  note,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.zemaColors.muted),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
