import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/sign_in.dart';
import 'widgets/account_page.dart';

/// S24: sign in with Google, or carry on as a guest.
///
/// Signing in, Continue as guest and back all return to the screen
/// underneath, or Home when opened from the account choice (S04), with a
/// "Signed in as" message after a sign-in. A cancelled picker stays here
/// with no message; a failure shows a short one.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final busy = ref.watch(signInProvider).isLoading;

    ref.listen(signInProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is NetworkFailure
                    ? l10n.signInOffline
                    : l10n.signInFailed,
              ),
            ),
          );
      }
    });

    Future<void> signIn() async {
      final user = await ref.read(signInProvider.notifier).signIn();
      if (user == null || !context.mounted) return;
      // Nothing else shows the user yet, so say who signed in.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.signInDone(user.name ?? user.email ?? '')),
          ),
        );
      _leave(context);
    }

    final canPop = GoRouter.of(context).canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.signInTitle),
          leading: canPop
              ? null
              : CloseButton(onPressed: () => context.go(AppRoutes.home)),
        ),
        body: SafeArea(
          top: false,
          child: AccountPage(
            content: [
              Text(
                l10n.signInHeading,
                style: textTheme.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: 16),
              const AccountBenefits(),
            ],
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.signInGoogleNote,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AccountActions(
                  primaryLabel: l10n.signInWithGoogle,
                  primaryIcon: Icons.account_circle_outlined,
                  onPrimary: signIn,
                  busy: busy,
                  secondaryLabel: l10n.accountContinueAsGuest,
                  onSecondary: () => _leave(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}
