import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/presentation/backup_screen.dart';
import '../application/contribution_starts.dart';
import '../application/drafts.dart';
import '../application/my_contributions.dart';
import '../application/own_copies.dart';

/// S23: the user's contributions in tabs Pending / Approved / Needs changes
/// / Rejected. Opening it fetches them again and clears the badge; a
/// Needs changes card reopens the flow to send it again.
class MyContributionsScreen extends ConsumerStatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  ConsumerState<MyContributionsScreen> createState() =>
      _MyContributionsScreenState();
}

const _tabs = [
  ContributionStatus.pending,
  ContributionStatus.approved,
  ContributionStatus.changesRequested,
  ContributionStatus.rejected,
];

class _MyContributionsScreenState extends ConsumerState<MyContributionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(myContributionsProvider.notifier);
      unawaited(notifier.markSeen());
      unawaited(notifier.check().then((_) => notifier.markSeen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(myContributionsProvider);
    final mine = state.mine;
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myContributionsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final status in _tabs)
                Tab(text: contributionStatusName(l10n, status)),
            ],
          ),
        ),
        body: mine == null
            ? Center(
                child: state.failure == null
                    ? const CircularProgressIndicator()
                    : _Offline(
                        onRetry: () =>
                            ref.read(myContributionsProvider.notifier).check(),
                      ),
              )
            : TabBarView(
                children: [
                  for (final status in _tabs)
                    _ContributionList([
                      for (final c in mine)
                        if (c.status == status) c,
                    ]),
                ],
              ),
      ),
    );
  }
}

/// The S23 tab name for [status].
String contributionStatusName(
  AppLocalizations l10n,
  ContributionStatus status,
) => switch (status) {
  ContributionStatus.pending => l10n.myContributionsPending,
  ContributionStatus.approved => l10n.myContributionsApproved,
  ContributionStatus.changesRequested => l10n.myContributionsNeedsChanges,
  ContributionStatus.rejected => l10n.myContributionsRejected,
};

String contributionKindName(AppLocalizations l10n, ContributionKind kind) =>
    switch (kind) {
      ContributionKind.newSong => l10n.contributionKindNewSong,
      ContributionKind.editLyrics => l10n.contributionKindCorrection,
      ContributionKind.recording => l10n.contributionKindRecording,
      ContributionKind.syncTiming => l10n.contributionKindSync,
    };

/// The song [c] is about: its own title, the catalog's, or this phone's own
/// copy's, else the song id.
String contributionTitle(WidgetRef ref, SubmittedContribution c) {
  if (c.contribution.song case final song?) return song.title;
  final songId = c.songId ?? c.contribution.songId ?? '';
  return ref.watch(catalogEntryProvider(songId))?.title ??
      ref
          .watch(ownCopiesProvider)
          .value
          ?.where((copy) => copy.contributionId == c.id)
          .firstOrNull
          ?.song
          .title ??
      songId;
}

class _Offline extends StatelessWidget {
  const _Offline({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(ZemaSpacing.screenSide),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.myContributionsOffline, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.actionTryAgain)),
        ],
      ),
    );
  }
}

class _ContributionList extends ConsumerWidget {
  const _ContributionList(this.contributions);

  final List<SubmittedContribution> contributions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> refresh() =>
        ref.read(myContributionsProvider.notifier).check();
    return RefreshIndicator(
      onRefresh: refresh,
      child: contributions.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(32),
              children: [
                Text(l10n.myContributionsEmpty, textAlign: TextAlign.center),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                12,
                ZemaSpacing.screenSide,
                24,
              ),
              children: [for (final c in contributions) _Card(c)],
            ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card(this.contribution);

  final SubmittedContribution contribution;

  /// Opens the draft sending this contribution again: the one already
  /// started, or a new one with what was sent.
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final c = contribution;
    final database = ref.read(databaseProvider);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    for (final saved in await database.draftsDao.all()) {
      if (saved.draft.resubmitId == c.id) {
        unawaited(router.push<void>(AppRoutes.draft(saved.id)));
        return;
      }
    }
    final copy = (await database.ownCopiesDao.all())
        .where((copy) => copy.contributionId == c.id)
        .firstOrNull;
    final needsCopy =
        c.contribution.song == null ||
        (c.kind == ContributionKind.syncTiming && copy?.recording == null);
    if (needsCopy && copy == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.myContributionsEditUnavailable)),
      );
      return;
    }
    final id = await startDraft(
      ref,
      draft: resubmitDraft(
        c,
        song: copy?.song,
        recording: copy?.recording,
        trackId: copy?.trackId,
        audioPath: copy?.audioPath,
      ),
    );
    unawaited(router.push<void>(AppRoutes.draft(id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final c = contribution;
    final reviewedAt = c.reviewedAt;
    final note = c.reviewNote;
    final pending = c.status == ContributionStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contributionTitle(ref, c),
              style: textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              [
                contributionKindName(l10n, c.kind),
                if (pending || reviewedAt == null)
                  l10n.myContributionsSent(
                    formatBackupTime(context, c.submittedAt),
                  )
                else
                  l10n.myContributionsReviewed(
                    formatBackupTime(context, reviewedAt),
                  ),
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
            if (!pending && note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                c.status == ContributionStatus.rejected
                    ? l10n.myContributionsReason(note)
                    : l10n.myContributionsComment(note),
                style: textTheme.bodyMedium,
              ),
            ],
            if (c.status == ContributionStatus.changesRequested) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonalIcon(
                  onPressed: () => _edit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.myContributionsEdit),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [child] with a dot when the user's contributions have news.
class ContributionBadge extends ConsumerWidget {
  const ContributionBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(myContributionsProvider.select((s) => s.badge));
    if (!badge) return child;
    return Semantics(
      label: AppLocalizations.of(context).myContributionsNew,
      child: Badge(smallSize: 10, child: child),
    );
  }
}
