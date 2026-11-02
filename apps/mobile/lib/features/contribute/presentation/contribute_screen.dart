import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/drafts_dao.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/account_providers.dart';
import '../../account/presentation/backup_screen.dart';
import '../application/drafts.dart';
import 'start_contribution.dart';

/// S05: how contributing works, Add lyrics and the user's drafts. Guests are
/// asked to sign in (C09) when they start; builds without a backend explain
/// that contributing needs one.
class ContributeScreen extends ConsumerWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(accountsAvailableProvider);
    final signedIn = ref.watch(authUserProvider).value != null;
    final drafts = signedIn
        ? ref.watch(draftsProvider).value ?? const <SavedDraft>[]
        : const <SavedDraft>[];
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            12,
            ZemaSpacing.screenSide,
            24,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(l10n.navContribute, style: textTheme.headlineMedium),
            ),
            Text(
              l10n.contributeSubtitle,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 16),
            const _HowItWorks(),
            const SizedBox(height: 16),
            if (available)
              FilledButton.icon(
                onPressed: () => startContribution(context, ref),
                icon: const Icon(Icons.edit_note),
                label: Text(l10n.contributeAddLyrics),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
              )
            else
              Text(
                l10n.contributeNoBackend,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                textAlign: TextAlign.center,
              ),
            if (drafts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.contributeDraftsTitle.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.muted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              for (final saved in drafts) _DraftTile(saved),
            ],
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      (l10n.contributeStepLyrics, l10n.contributeStepLyricsBody),
      (l10n.contributeStepRecording, l10n.contributeStepRecordingBody),
      (l10n.contributeStepSync, l10n.contributeStepSyncBody),
      (l10n.contributeStepReview, l10n.contributeStepReviewBody),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.contributeHowTitle,
              style: textTheme.titleMedium?.copyWith(color: colors.text),
            ),
            for (final (i, (title, body)) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: colors.soft,
                      child: Text(
                        '${i + 1}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.text,
                            ),
                          ),
                          Text(
                            body,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The name of [step], as shown in the drafts list.
String draftStepName(AppLocalizations l10n, DraftStep step) => switch (step) {
  DraftStep.lyrics => l10n.contributeStepLyrics,
  DraftStep.recording => l10n.contributeStepRecording,
  DraftStep.sync => l10n.contributeStepSync,
  DraftStep.review => l10n.contributeStepReview,
};

class _DraftTile extends ConsumerWidget {
  const _DraftTile(this.saved);

  final SavedDraft saved;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.contributeDraftDeleteTitle),
        content: Text(l10n.contributeDraftDeleteMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.contributeDraftDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await deleteDraft(ref, saved.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final title = saved.draft.title.isEmpty
        ? l10n.contributeDraftUntitled
        : saved.draft.title;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.tile,
        foregroundColor: colors.tileFg,
        child: const Icon(Icons.edit_note),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.contributeDraftSubtitle(
          draftStepName(l10n, saved.draft.step),
          formatBackupTime(context, saved.updatedAt),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: l10n.contributeDraftDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(context, ref, title),
      ),
      onTap: () => context.push<void>(AppRoutes.draft(saved.id)),
    );
  }
}
