import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../../account/presentation/backup_screen.dart';
import '../application/moderation.dart';
import 'my_contributions_screen.dart';

/// S23m: other users' pending contributions, oldest first, with their
/// count and a filter by kind, then fingerprints shared from libraries.
/// Moderators only.
class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  /// Only this kind, or all.
  ContributionKind? _kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final queue = ref.watch(reviewQueueProvider);
    final items = queue.value;
    final shown = [
      for (final item in items ?? const <QueuedContribution>[])
        if (_kind == null || item.kind == _kind) item,
    ];
    Widget chip(ContributionKind? kind, String label) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _kind == kind,
        onSelected: (_) => setState(() => _kind = kind),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewQueueTitle)),
      body: switch (items) {
        null when queue.hasError => Center(
          child: Padding(
            padding: const EdgeInsets.all(ZemaSpacing.screenSide),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.reviewQueueOffline, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(reviewQueueProvider),
                  child: Text(l10n.actionTryAgain),
                ),
              ],
            ),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        _ => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(pendingFingerprintsProvider);
            return ref
                .read(reviewQueueProvider.notifier)
                .refresh()
                .catchError((Object _) {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              8,
              ZemaSpacing.screenSide,
              24,
            ),
            children: [
              Text(
                l10n.reviewQueueCount(shown.length),
                style: textTheme.titleSmall?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chip(null, l10n.reviewQueueAll),
                    for (final kind in ContributionKind.values)
                      chip(kind, contributionKindName(l10n, kind)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.reviewQueueEmpty,
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final item in shown) _QueueTile(item),
              const _FingerprintsSection(),
            ],
          ),
        ),
      },
    );
  }
}

/// The song a queued contribution is about.
String queuedTitle(QueuedContribution item) =>
    item.contribution.song?.title ??
    item.currentSong?.song.title ??
    item.contribution.songId ??
    '';

class _QueueTile extends StatelessWidget {
  const _QueueTile(this.item);

  final QueuedContribution item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final date = formatBackupTime(context, item.submittedAt);
    final name = item.authorName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.tile,
        foregroundColor: colors.tileFg,
        child: Icon(switch (item.kind) {
          ContributionKind.newSong => Icons.library_music_outlined,
          ContributionKind.editLyrics => Icons.edit_note,
          ContributionKind.recording => Icons.link,
          ContributionKind.syncTiming => Icons.timer_outlined,
        }),
      ),
      title: Text(
        queuedTitle(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          contributionKindName(l10n, item.kind),
          if (name == null)
            l10n.myContributionsSent(date)
          else
            l10n.reviewQueueBy(name, date),
          if (item.revision > 1) l10n.reviewQueueResent,
        ].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push<void>(AppRoutes.reviewItem(item.id)),
    );
  }
}

/// Library fingerprints no second phone has confirmed: publish or drop.
class _FingerprintsSection extends ConsumerWidget {
  const _FingerprintsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pendingFingerprintsProvider).value;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    Future<void> decide(PendingFingerprint item, {required bool approve}) => ref
        .read(pendingFingerprintsProvider.notifier)
        .decide(item.id, approve: approve)
        .catchError((Object _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.reviewFingerprintFailed)));
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.reviewQueueFingerprints,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: colors.muted),
        ),
        for (final item in items)
          ListTile(
            key: ValueKey(item.id),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: colors.tile,
              foregroundColor: colors.tileFg,
              child: const Icon(Icons.graphic_eq),
            ),
            title: Text(
              [item.songTitle, ?item.recordingArtist].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              l10n.reviewFingerprintDetail(
                item.installs,
                formatDuration(item.duration),
                switch (item.recordingDuration) {
                  final length? => formatDuration(length),
                  null => '–',
                },
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.reviewFingerprintDrop,
                  icon: const Icon(Icons.close),
                  onPressed: () => unawaited(decide(item, approve: false)),
                ),
                IconButton(
                  tooltip: l10n.reviewFingerprintPublish,
                  icon: const Icon(Icons.check),
                  onPressed: () => unawaited(decide(item, approve: true)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
