import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/empty_state.dart';
import 'routes.dart';

/// Shown for any route that doesn't exist, instead of crashing.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          kind: EmptyStateKind.error,
          title: l10n.errorNotFoundTitle,
          message: l10n.errorNotFoundMessage,
          actionLabel: l10n.actionGoHome,
          onAction: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
