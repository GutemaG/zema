import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/backup.dart';
import '../application/backup_service.dart';
import '../data/backup_status.dart';

/// S25b: Backup & sync, opened from Settings → Account & backup and from
/// Profile. The last backup and any error, Back up now, Restore (S26) and
/// Auto backup,
/// then what a backup holds and leaves out.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(backupProvider);
    final status = state.status;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZemaSpacing.screenSide,
          8,
          ZemaSpacing.screenSide,
          24,
        ),
        children: [
          if (status != null)
            _StatusGroup(status: status, running: state.running),
          _Note(title: l10n.backupIncludedTitle, body: l10n.backupIncluded),
          _Note(
            title: l10n.backupNotIncludedTitle,
            body: l10n.backupNotIncluded,
          ),
        ],
      ),
    );
  }
}

/// [date] in the user's language, e.g. "Oct 30, 2026, 2:15 PM".
String formatBackupTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final material = MaterialLocalizations.of(context);
  return AppLocalizations.of(context).backupLastAt(
    material.formatMediumDate(local),
    material.formatTimeOfDay(TimeOfDay.fromDateTime(local)),
  );
}

class _StatusGroup extends ConsumerWidget {
  const _StatusGroup({required this.status, required this.running});

  final BackupStatus status;
  final bool running;

  Future<void> _backUp(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(backupProvider.notifier);
    var result = await controller.backUpNow();
    if (result case (
      outcome: BackupOutcome.otherBackup,
      otherSavedAt: final DateTime cloud,
    )) {
      if (!context.mounted) return;
      final replace = await _confirmReplace(context, cloud);
      if (!replace) return;
      result = await controller.backUpNow(replace: true);
    }
    final message = switch (result?.outcome) {
      BackupOutcome.done || BackupOutcome.unchanged => l10n.backupDone,
      BackupOutcome.offline => l10n.backupOffline,
      BackupOutcome.failed => l10n.backupFailed,
      BackupOutcome.otherBackup || null => null,
    };
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static Future<bool> _confirmReplace(
    BuildContext context,
    DateTime cloud,
  ) async {
    final l10n = AppLocalizations.of(context);
    final date = formatBackupTime(context, cloud);
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupReplaceTitle),
        content: Text(l10n.backupReplaceMessage(date)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupReplace),
          ),
        ],
      ),
    );
    return replace ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final last = status.lastBackupAt;
    final error = switch (status.lastError) {
      BackupError.offline => l10n.backupErrorOffline,
      BackupError.failed => l10n.backupErrorFailed,
      BackupError.otherBackup => l10n.backupErrorOther,
      null => null,
    };
    return SettingsGroup(
      title: l10n.backupSectionStatus,
      children: [
        SettingsRow(
          label: l10n.backupLast,
          value: last == null
              ? l10n.backupNever
              : formatBackupTime(context, last),
        ),
        if (error != null)
          SettingsRow(
            label: error,
            labelColor: Theme.of(context).colorScheme.error,
          ),
        SettingsRow(
          label: l10n.backupNow,
          onTap: running ? null : () => unawaited(_backUp(context, ref)),
          trailing: running
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : null,
        ),
        SettingsRow(
          label: l10n.backupRestore,
          onTap: running ? null : () => context.push(AppRoutes.restore),
        ),
        SettingsRow(
          label: l10n.backupAuto,
          value: l10n.backupAutoNote,
          trailing: Switch(
            value: status.autoBackup,
            onChanged: (on) =>
                unawaited(ref.read(backupProvider.notifier).setAutoBackup(on)),
          ),
        ),
      ],
    );
  }
}

/// A heading and a paragraph about what a backup holds.
class _Note extends StatelessWidget {
  const _Note({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(color: colors.text),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
