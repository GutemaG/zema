import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/account_providers.dart';
import '../../application/profile.dart';
import 'account_avatar.dart';

/// The Home header's account button: the avatar, or a guest icon, opening
/// Profile (S25). Builds that can't sign in have no Profile, so it is the
/// Settings button there.
class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const tap = BoxConstraints(
      minWidth: ZemaSpacing.minTap,
      minHeight: ZemaSpacing.minTap,
    );
    if (!ref.watch(signInAvailableProvider)) {
      return IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: l10n.homeSettingsTooltip,
        constraints: tap,
        onPressed: () => context.push(AppRoutes.settings),
      );
    }
    return IconButton(
      icon: AccountAvatar(profile: ref.watch(profileProvider).value, size: 32),
      tooltip: l10n.homeProfileTooltip,
      constraints: tap,
      onPressed: () => context.push(AppRoutes.profile),
    );
  }
}
