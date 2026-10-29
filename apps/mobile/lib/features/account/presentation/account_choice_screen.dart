import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/sign_in.dart';
import 'widgets/account_page.dart';

/// S04: the one-time choice before Home, guest (the default) or sign in.
class AccountChoiceScreen extends ConsumerWidget {
  const AccountChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;

    Future<void> choose(String location) async {
      await ref.read(accountChoicePendingProvider.notifier).chosen();
      if (context.mounted) context.go(location);
    }

    return Scaffold(
      body: SafeArea(
        child: AccountPage(
          content: [
            Icon(Icons.music_note_rounded, size: 48, color: colors.accentText),
            const SizedBox(height: 16),
            Text(
              l10n.accountChoiceTitle,
              style: textTheme.headlineSmall?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.accountChoiceMessage,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 16),
            const AccountBenefits(),
          ],
          actions: AccountActions(
            primaryLabel: l10n.accountContinueAsGuest,
            onPrimary: () => choose(AppRoutes.home),
            secondaryLabel: l10n.accountSignIn,
            onSecondary: () => choose(AppRoutes.signIn),
          ),
        ),
      ),
    );
  }
}
