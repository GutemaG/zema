import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/restore_dao.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/restore.dart';
import 'backup_screen.dart';
import 'widgets/account_page.dart';

/// S26: after sign-in when the account has a cloud backup, or from Backup
/// & sync. "We found your backup from (date): N favorites, N playlists,
/// settings", with Restore and Start fresh; then a summary with the songs
/// not found on this phone.
class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  /// Back to the screen underneath, or Home when opened after S04.
  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(restoreProvider);
    final controller = ref.read(restoreProvider.notifier);
    final busy = state is RestoreRunning || state is RestoreLoading;
    final canPop = GoRouter.of(context).canPop();

    return PopScope(
      canPop: canPop && state is! RestoreRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state is! RestoreRunning) context.go(AppRoutes.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.restoreTitle),
          leading: canPop || busy
              ? null
              : CloseButton(onPressed: () => _leave(context)),
          automaticallyImplyLeading: state is! RestoreRunning,
        ),
        body: SafeArea(
          top: false,
          child: switch (state) {
            RestoreLoading() => _Progress(l10n.restoreLoading),
            RestoreRunning(:final waitingForScan) => _Progress(
              waitingForScan ? l10n.restoreWaitingForScan : l10n.restoreRunning,
            ),
            RestoreFound(:final backup) => AccountPage(
              content: [_Found(backup)],
              actions: AccountActions(
                primaryLabel: l10n.restoreAction,
                primaryIcon: Icons.restore,
                onPrimary: controller.restore,
                secondaryLabel: l10n.restoreStartFresh,
                onSecondary: () => _leave(context),
              ),
            ),
            RestoreNone() => _Message(
              text: l10n.restoreNone,
              action: l10n.restoreDone,
              onAction: () => _leave(context),
            ),
            RestoreError(:final failure) => _Message(
              text: switch (failure) {
                BackupFormatFailure(newerFormat: true) => l10n.restoreNewer,
                NetworkFailure() => l10n.restoreOffline,
                _ => l10n.restoreFailed,
              },
              action: failure is BackupFormatFailure && failure.newerFormat
                  ? l10n.restoreDone
                  : l10n.restoreRetry,
              onAction: failure is BackupFormatFailure && failure.newerFormat
                  ? () => _leave(context)
                  : controller.load,
            ),
            RestoreDone(:final report) => _Done(
              report: report,
              onDone: () => _leave(context),
            ),
          },
        ),
      ),
    );
  }
}

class _Found extends StatelessWidget {
  const _Found(this.backup);

  final StoredBackup backup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final document = backup.document;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.cloud_done_outlined, size: 48, color: colors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.restoreFound(
            formatBackupTime(context, backup.savedAt),
            l10n.restoreCountFavorites(document.favorites.length),
            l10n.restoreCountPlaylists(document.playlists.length),
          ),
          style: textTheme.titleLarge?.copyWith(color: colors.text),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.restoreMergeNote,
          style: textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.restoreStartFreshNote,
          style: textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.report, required this.onDone});

  final RestoreReport report;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final notFound = report.songsNotFound;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                l10n.restoreDoneTitle,
                style: textTheme.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: 12),
              for (final line in [
                l10n.restoreDoneFavorites(report.favoritesAdded),
                l10n.restoreDonePlaylists(report.playlistSongsAdded),
                l10n.restoreDoneChoices(report.lyricsChoicesAdded),
                l10n.restoreDoneSettings,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: textTheme.bodyLarge?.copyWith(color: colors.text),
                  ),
                ),
              if (notFound.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.restoreNotFoundTitle(notFound.length),
                  style: textTheme.titleMedium?.copyWith(color: colors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.restoreNotFoundNote,
                  style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 8),
                for (final song in notFound)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      Icons.music_off_outlined,
                      color: colors.muted,
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: colors.text),
                    ),
                    subtitle: Text(
                      song.artist ?? song.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.restoreDone),
          ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(120, 48),
                shape: const StadiumBorder(),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
