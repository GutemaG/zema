import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zema_core/zema_core.dart';

import '../../account/application/account_providers.dart';
import '../../account/application/profile.dart';

/// Whether the signed-in user may review others' contributions.
final isModeratorProvider = Provider<bool>(
  (ref) => ref.watch(profileProvider).value?.isModerator ?? false,
);

/// Opens [url] in the app that handles it (YouTube for a video). Tests
/// override it.
final openUrlProvider = Provider<Future<bool> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

/// Other users' pending contributions, oldest first (S23m); empty for
/// anyone but a moderator.
final reviewQueueProvider =
    AsyncNotifierProvider.autoDispose<ReviewQueue, List<QueuedContribution>>(
      ReviewQueue.new,
    );

class ReviewQueue extends AsyncNotifier<List<QueuedContribution>> {
  @override
  Future<List<QueuedContribution>> build() async {
    final repository = ref.watch(contributionRepositoryProvider);
    if (repository == null || !ref.watch(isModeratorProvider)) return const [];
    return repository.queue();
  }

  /// Fetches the queue again. Throws the repository's failures, and the
  /// last queue stays.
  Future<void> refresh() async {
    final repository = ref.read(contributionRepositoryProvider);
    if (repository == null) return;
    final queue = await repository.queue();
    if (ref.mounted) state = AsyncData(queue);
  }

  /// Decides on item [id] ([note] is required unless approving) and takes
  /// it out of the queue. Throws the repository's failures; when someone
  /// else reviewed it first ([ContributionError.alreadyReviewed]) the queue
  /// is fetched again first.
  Future<void> decide(
    String id,
    ReviewDecision decision, {
    String? note,
  }) async {
    final repository =
        ref.read(contributionRepositoryProvider) ??
        (throw const AuthFailure('No backend'));
    try {
      await repository.review(id, decision, note: note);
    } on ContributionFailure catch (e) {
      if (e.code == ContributionError.alreadyReviewed.code) {
        await refresh().catchError((Object _) {});
      }
      rethrow;
    }
    if (!ref.mounted) return;
    state = AsyncData([
      for (final item in state.value ?? const <QueuedContribution>[])
        if (item.id != id) item,
    ]);
  }
}

/// Library fingerprints waiting for a moderator, oldest first (S23m); empty
/// for anyone but a moderator.
final pendingFingerprintsProvider =
    AsyncNotifierProvider.autoDispose<
      PendingFingerprints,
      List<PendingFingerprint>
    >(PendingFingerprints.new);

class PendingFingerprints extends AsyncNotifier<List<PendingFingerprint>> {
  @override
  Future<List<PendingFingerprint>> build() async {
    final repository = ref.watch(contributionRepositoryProvider);
    if (repository == null || !ref.watch(isModeratorProvider)) return const [];
    return repository.pendingFingerprints();
  }

  /// Publishes ([approve]) or drops fingerprint [id] and takes it off the
  /// list, with the others for its recording when published. Throws the
  /// repository's failures.
  Future<void> decide(String id, {required bool approve}) async {
    final repository =
        ref.read(contributionRepositoryProvider) ??
        (throw const AuthFailure('No backend'));
    await repository.reviewFingerprint(id, approve: approve);
    if (!ref.mounted) return;
    final items = state.value ?? const <PendingFingerprint>[];
    final recording = items.where((f) => f.id == id).firstOrNull?.recordingId;
    state = AsyncData([
      for (final item in items)
        if (item.id != id && !(approve && item.recordingId == recording)) item,
    ]);
  }
}
