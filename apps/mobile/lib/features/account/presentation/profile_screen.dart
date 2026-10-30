import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/profile.dart';
import 'widgets/account_avatar.dart';
import 'widgets/account_page.dart';
import 'widgets/rename_dialog.dart';

/// S25: the signed-in user's avatar, name (editable) and role, with
/// Backup & sync, Settings, Sign out and Delete account; for a guest, a
/// sign-in card and Settings.
///
/// Stats and My contributions join in intent 006.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    final running = ref.watch(accountActionsProvider);
    final busy = running != null;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileTitle),
          titleTextStyle: Theme.of(context).textTheme.headlineSmall,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                8,
                ZemaSpacing.screenSide,
                24,
              ),
              children: [
                if (profile == null)
                  const _GuestHeader()
                else
                  _ProfileHeader(profile: profile),
                SettingsGroup(
                  title: l10n.profileSectionGeneral,
                  children: [
                    if (profile != null)
                      SettingsRow(
                        label: l10n.backupTitle,
                        onTap: () => context.push(AppRoutes.backup),
                      ),
                    SettingsRow(
                      label: l10n.settingsTitle,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
                if (profile != null) const _AccountGroup(),
              ],
            ),
            if (busy)
              _Busy(
                label: running == AccountAction.deleteAccount
                    ? l10n.profileDeleting
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final Profile profile;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await showRenameDialog(context, profile.displayName);
    if (name == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileProvider.notifier).rename(name);
    } on Object catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is NetworkFailure
                  ? l10n.profileNameOffline
                  : l10n.profileNameFailed,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        AccountAvatar(profile: profile, size: 88),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Balances the edit button, so the name stays centered.
            const SizedBox(width: ZemaSpacing.minTap),
            Flexible(
              child: Text(
                profile.displayName,
                style: textTheme.headlineSmall?.copyWith(color: colors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.profileEditName,
              color: colors.muted,
              constraints: const BoxConstraints(
                minWidth: ZemaSpacing.minTap,
                minHeight: ZemaSpacing.minTap,
              ),
              onPressed: () => _rename(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _RoleBadge(roles: profile.roles),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.roles});

  final Set<AccountRole> roles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final label = roles.contains(AccountRole.admin)
        ? l10n.profileRoleAdmin
        : roles.contains(AccountRole.moderator)
        ? l10n.profileRoleModerator
        : l10n.profileRoleContributor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(ZemaRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.accentText),
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AccountAvatar(profile: null, size: 88)),
        const SizedBox(height: 12),
        Text(
          l10n.profileGuestName,
          style: textTheme.headlineSmall?.copyWith(color: colors.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZemaRadius.medium),
            side: BorderSide(color: colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileSignInCardTitle,
                  style: textTheme.titleMedium?.copyWith(color: colors.text),
                ),
                const SizedBox(height: 8),
                const AccountBenefits(),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.signIn),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.accountSignIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Sign out and Delete account, each after confirming.
class _AccountGroup extends ConsumerWidget {
  const _AccountGroup();

  // Both actions sign out, which removes this group before they return, so
  // the messenger is looked up beforehand.
  static void _show(ScaffoldMessengerState messenger, String message) =>
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.profileSignOutTitle,
      message: l10n.profileSignOutMessage,
      action: l10n.profileSignOut,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (await ref.read(accountActionsProvider.notifier).signOut()) {
      _show(messenger, l10n.profileSignedOut);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final first = await _confirm(
      context,
      title: l10n.profileDeleteTitle,
      message: l10n.profileDeleteMessage,
      action: l10n.profileDeleteContinue,
    );
    if (!first || !context.mounted) return;
    final second = await _confirm(
      context,
      title: l10n.profileDeleteConfirmTitle,
      message: l10n.profileDeleteConfirmMessage,
      action: l10n.actionDelete,
      destructive: true,
    );
    if (!second || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    String? message;
    try {
      final deleted = await ref
          .read(accountActionsProvider.notifier)
          .deleteAccount();
      if (deleted) message = l10n.profileDeleted;
    } on Object catch (e) {
      message = e is NetworkFailure
          ? l10n.profileDeleteOffline
          : l10n.profileDeleteFailed;
    }
    if (message != null) _show(messenger, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      title: l10n.profileSectionAccount,
      children: [
        SettingsRow(
          label: l10n.profileSignOut,
          onTap: () => _signOut(context, ref),
          trailing: const SizedBox.shrink(),
        ),
        SettingsRow(
          label: l10n.profileDeleteAccount,
          labelColor: Theme.of(context).colorScheme.error,
          onTap: () => _delete(context, ref),
          trailing: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A confirmation dialog; true when [action] was pressed. A [destructive]
/// action is a red filled button.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          if (destructive)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: Text(action),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Covers the screen while an account action runs, so nothing else can be
/// tapped, with [label] under the spinner when given.
class _Busy extends StatelessWidget {
  const _Busy({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: colors.bg.withValues(alpha: 0.7),
        ),
        Center(
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(ZemaRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (label case final label?) ...[
                    const SizedBox(height: 16),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
