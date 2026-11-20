import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import 'format.dart';
import 'session.dart';
import 'strings.dart';

/// Library fingerprints phones shared, waiting for a moderator.
final pendingFingerprintsProvider =
    FutureProvider.autoDispose<List<PendingFingerprint>>(
      (ref) => ref.watch(contributionRepositoryProvider).pendingFingerprints(),
    );

/// Track prints phones shared (intent 013), waiting for a moderator.
final pendingTrackPrintsProvider =
    FutureProvider.autoDispose<List<PendingTrackPrint>>(
      (ref) => ref.watch(contributionRepositoryProvider).pendingTrackPrints(),
    );

/// Shared fingerprints and track prints to publish or drop.
class FingerprintsPage extends ConsumerWidget {
  const FingerprintsPage({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(ContributionRepository repository) decide, {
    required bool approve,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await decide(ref.read(contributionRepositoryProvider));
      messenger.showSnackBar(
        SnackBar(content: Text(approve ? Strings.approved : Strings.rejected)),
      );
    } on ZemaFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is NetworkFailure ? Strings.offline : e.message),
        ),
      );
    }
    ref
      ..invalidate(pendingFingerprintsProvider)
      ..invalidate(pendingTrackPrintsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final fingerprints = ref.watch(pendingFingerprintsProvider);
    final prints = ref.watch(pendingTrackPrintsProvider);
    if (fingerprints.error ?? prints.error case final error?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error is NetworkFailure ? Strings.offline : '$error'),
            TextButton(
              onPressed: () => ref
                ..invalidate(pendingFingerprintsProvider)
                ..invalidate(pendingTrackPrintsProvider),
              child: const Text(Strings.retry),
            ),
          ],
        ),
      );
    }
    return switch ((fingerprints, prints)) {
      (AsyncData(value: final shared), AsyncData(value: final printed))
          when shared.isEmpty && printed.isEmpty =>
        const Center(child: Text(Strings.fingerprintsEmpty)),
      (AsyncData(value: final shared), AsyncData(value: final printed)) =>
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (shared.isNotEmpty) const _Header(Strings.libraryFingerprints),
            for (final item in shared)
              _ReviewCard(
                title: item.songTitle,
                details: [
                  item.recordingArtist ?? Strings.unknownArtist,
                  if (item.recordingDuration case final d?) formatDuration(d),
                  '${item.hashCount} ${Strings.hashes}',
                  '${item.installs} ${Strings.installs}',
                  formatAge(item.sentAt),
                ],
                muted: muted,
                onReview: (approve) => _review(
                  context,
                  ref,
                  (r) => r.reviewFingerprint(item.id, approve: approve),
                  approve: approve,
                ),
              ),
            if (printed.isNotEmpty) const _Header(Strings.trackPrints),
            for (final item in printed)
              _ReviewCard(
                title: item.songTitle,
                details: [
                  item.songArtist ?? Strings.unknownArtist,
                  formatDuration(item.duration),
                  '${item.installs} ${Strings.installs}',
                  formatAge(item.sentAt),
                ],
                warning: switch (item.conflictSongTitle) {
                  final other? => '${Strings.alsoMatches} “$other”',
                  null => null,
                },
                muted: muted,
                onReview: (approve) => _review(
                  context,
                  ref,
                  (r) => r.reviewTrackPrint(item.id, approve: approve),
                  approve: approve,
                ),
              ),
          ],
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.details,
    required this.muted,
    required this.onReview,
    this.warning,
  });

  final String title;
  final List<String> details;
  final String? warning;
  final TextStyle muted;
  final void Function(bool approve) onReview;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details.join(' · '), style: muted),
          if (warning case final w?)
            Text(
              w,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => onReview(false),
            child: const Text(Strings.reject),
          ),
          FilledButton(
            onPressed: () => onReview(true),
            child: const Text(Strings.approve),
          ),
        ],
      ),
    ),
  );
}
