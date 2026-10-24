import 'package:flutter/material.dart';

import '../../app/theme/zema_colors.dart';
import '../../app/theme/zema_spacing.dart';

/// Which C07 state to show. Each kind has its own icon.
enum EmptyStateKind {
  empty(Icons.inbox_outlined),
  error(Icons.error_outline),
  offline(Icons.cloud_off_outlined);

  const EmptyStateKind(this.icon);

  final IconData icon;
}

/// C07: the shared empty / error / offline state.
///
/// Centered on the screen, and scrolls instead of overflowing when there is
/// not enough height. The action button only appears when both
/// [actionLabel] and [onAction] are given, and the secondary text button
/// likewise; callers own retry logic. [icon] replaces the kind's icon.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon,
  });

  final EmptyStateKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = actionLabel;
    final action = onAction;
    final secondaryLabel = secondaryActionLabel;
    final secondaryAction = onSecondaryAction;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight
                  ? (constraints.maxHeight - 48).clamp(0, double.infinity)
                  : 0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon ?? kind.icon, size: 48, color: colors.muted),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(color: colors.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                    textAlign: TextAlign.center,
                  ),
                  if (label != null && action != null) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: action,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        minimumSize: const Size(
                          ZemaSpacing.minTap,
                          ZemaSpacing.minTap,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(label),
                    ),
                  ],
                  if (secondaryLabel != null && secondaryAction != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: secondaryAction,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        minimumSize: const Size(
                          ZemaSpacing.minTap,
                          ZemaSpacing.minTap,
                        ),
                      ),
                      child: Text(secondaryLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
