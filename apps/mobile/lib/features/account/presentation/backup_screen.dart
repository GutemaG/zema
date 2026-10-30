import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// S25b: Backup & sync, opened from Settings → Account & backup and from
/// Profile. Lists what a backup holds and leaves out.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
