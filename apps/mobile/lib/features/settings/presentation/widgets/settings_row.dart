import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';

/// A Settings row: label on the left, current [value] and › on the right.
///
/// Without [onTap] the row is informational and shows no ›. A [trailing]
/// widget (a switch, a spinner) replaces the ›. Screen readers get one node
/// per row, reading the label and value together.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.labelColor,
  });

  static const double minHeight = 56;

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// The label's color, e.g. the error color for a destructive action;
  /// `text` by default.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.bodyLarge?.copyWith(
                        color: labelColor ?? colors.text,
                      ),
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 12),
                    // Up to half the row, pushed against the end (or the ›).
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          value,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: 12),
                    trailing,
                  ] else if (onTap != null)
                    Icon(Icons.chevron_right, size: 20, color: colors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
