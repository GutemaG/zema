import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      title: l10n.appTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.homeSettingsTooltip,
          constraints: const BoxConstraints(
            minWidth: ZemaSpacing.minTap,
            minHeight: ZemaSpacing.minTap,
          ),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
      child: EmptyState(
        kind: EmptyStateKind.empty,
        title: l10n.comingSoonTitle,
        message: l10n.homeComingSoonMessage,
      ),
    );
  }
}
