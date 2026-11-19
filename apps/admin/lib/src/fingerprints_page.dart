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

class FingerprintsPage extends ConsumerWidget {
  const FingerprintsPage({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    PendingFingerprint item, {
    required bool approve,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(contributionRepositoryProvider)
          .reviewFingerprint(item.id, approve: approve);
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
    ref.invalidate(pendingFingerprintsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return switch (ref.watch(pendingFingerprintsProvider)) {
      AsyncData(value: final items) when items.isEmpty => const Center(
        child: Text(Strings.fingerprintsEmpty),
      ),
      AsyncData(value: final items) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item.songTitle),
                subtitle: Text(
                  [
                    item.recordingArtist ?? Strings.unknownArtist,
                    if (item.recordingDuration case final d?) formatDuration(d),
                    '${item.hashCount} ${Strings.hashes}',
                    '${item.installs} ${Strings.installs}',
                    formatAge(item.sentAt),
                  ].join(' · '),
                  style: muted,
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          _review(context, ref, item, approve: false),
                      child: const Text(Strings.reject),
                    ),
                    FilledButton(
                      onPressed: () =>
                          _review(context, ref, item, approve: true),
                      child: const Text(Strings.approve),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      AsyncError(:final error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error is NetworkFailure ? Strings.offline : '$error'),
            TextButton(
              onPressed: () => ref.invalidate(pendingFingerprintsProvider),
              child: const Text(Strings.retry),
            ),
          ],
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
