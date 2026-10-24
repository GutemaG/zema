import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';

/// A titled card of [children] rows, separated by dividers, as on the S28
/// canvas.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.muted, letterSpacing: 0.8),
            ),
          ),
        ),
        Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZemaRadius.medium),
            side: BorderSide(color: colors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
