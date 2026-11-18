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
import '../application/moderation.dart';
import '../application/own_copies.dart';
import 'my_contributions_screen.dart';
import 'start_contribution.dart';

/// S05: how contributing works, Add lyrics, the drafts (guests' too, since
/// drafts and lyrics saved on this phone need no account), and for signed-in
/// users My contributions, and for moderators the review queue. Builds
/// without a backend explain that contributing needs one.
class ContributeScreen extends ConsumerWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(accountsAvailableProvider);
    final signedIn = ref.watch(authUserProvider).value != null;
    final drafts = ref.watch(draftsProvider).value ?? const <SavedDraft>[];
    final savedLocally = {
      for (final copy in ref.watch(ownCopiesProvider).value ?? const [])
        ?copy.localDraftId,
    };
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
            ),
            if (!available) ...[
              const SizedBox(height: 8),
              Text(
                l10n.contributeNoBackend,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                textAlign: TextAlign.center,
              ),
            ],
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
              for (final saved in drafts)
                _DraftTile(
                  saved,
                  savedLocally: savedLocally.contains(saved.id),
                ),
            ],
            if (signedIn) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const ContributionBadge(
                  child: Icon(Icons.history_edu_outlined),
                ),
                title: Text(l10n.myContributionsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push<void>(AppRoutes.myContributions),
              ),
              if (ref.watch(isModeratorProvider))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(l10n.reviewQueueTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push<void>(AppRoutes.reviewQueue),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// How contributing works: the title alone until tapped, then the steps.
class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  var _open = false;

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
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.primaryText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.contributeHowTitle,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    for (final (i, (title, body)) in steps.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
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
  const _DraftTile(this.saved, {required this.savedLocally});

  final SavedDraft saved;

  /// Whether its lyrics are saved on this phone.
  final bool savedLocally;

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
        savedLocally
            ? l10n.contributeDraftSavedLocal(
                formatBackupTime(context, saved.updatedAt),
              )
            : l10n.contributeDraftSubtitle(
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
