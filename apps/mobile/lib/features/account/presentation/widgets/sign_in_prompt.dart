import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/account_providers.dart';

/// C09: tells a guest why [reason] needs an account, with Sign in and Not
/// now. Sign in opens S24, which returns here. Whether the user ended
/// signed in; Not now (or dismissing) changes nothing.
Future<bool> showSignInPrompt(
  BuildContext context, {
  required String reason,
}) async {
  final signIn = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    // Sized to its content, so large text still shows both buttons.
    isScrollControlled: true,
    builder: (_) => SignInPrompt(reason: reason),
  );
  if (signIn != true || !context.mounted) return false;
  await context.push<void>(AppRoutes.signIn);
  if (!context.mounted) return false;
  final auth = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(authRepositoryProvider);
  return auth?.currentUser != null;
}

/// The body of C09; see [showSignInPrompt].
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.signInPromptTitle,
              style: textTheme.titleLarge?.copyWith(color: colors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.accountSignIn),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: colors.text,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.signInPromptNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
