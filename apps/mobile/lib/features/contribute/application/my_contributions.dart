import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/preferences_provider.dart';
import '../../account/application/account_providers.dart';
import '../data/contribution_seen.dart';
import 'own_copies.dart';

final contributionSeenStoreProvider = Provider<ContributionSeenStore>(
  (ref) => ContributionSeenStore(ref.watch(sharedPreferencesProvider)),
);

/// The signed-in user's contributions as last fetched, and which changed
/// since S23 was last opened.
@immutable
class MyContributions {
  const MyContributions({this.mine, this.unseen = const {}, this.failure});

  /// Last sent first; null until fetched.
  final List<SubmittedContribution>? mine;
  final Set<String> unseen;

  /// Why the last fetch failed, or null.
  final ZemaFailure? failure;

  /// The badge on Profile and S05's link.
  bool get badge => unseen.isNotEmpty;
}

/// Contributions whose status changed, one list per check that found any;
/// the shell shows a message for each.
final contributionChangesProvider = StreamProvider<List<SubmittedContribution>>(
  (ref) => ref.watch(_changesProvider).stream,
);

final _changesProvider =
    Provider<StreamController<List<SubmittedContribution>>>((ref) {
      final changes = StreamController<List<SubmittedContribution>>.broadcast();
      ref.onDispose(changes.close);
      return changes;
    });

/// Fetches the user's contributions when they are known at start, when the
/// app comes back to the foreground, and on [MyContributionsNotifier.check].
/// Each fetch applies reviews to the own copies and tells about new
/// reviews. Kept alive by the shell.
final myContributionsProvider =
    NotifierProvider<MyContributionsNotifier, MyContributions>(
      MyContributionsNotifier.new,
    );

class MyContributionsNotifier extends Notifier<MyContributions> {
  Future<void>? _checking;

  @override
  MyContributions build() {
    final userId = ref.watch(authUserProvider.select((u) => u.value?.id));
    if (userId == null) return const MyContributions();
    final lifecycle = AppLifecycleListener(onResume: () => unawaited(check()));
    ref.onDispose(lifecycle.dispose);
    scheduleMicrotask(() => unawaited(check()));
    return MyContributions(
      unseen: ref.read(contributionSeenStoreProvider).read(userId).unseen,
    );
  }

  /// Fetches the user's contributions; one fetch at a time. Offline or
  /// refused, what was shown stays, with [MyContributions.failure] set.
  Future<void> check() =>
      _checking ??= _check().whenComplete(() => _checking = null);

  Future<void> _check() async {
    final repository = ref.read(contributionRepositoryProvider);
    final userId = ref.read(authUserProvider).value?.id;
    if (repository == null || userId == null) return;
    bool same() =>
        ref.mounted && ref.read(authUserProvider).value?.id == userId;
    final List<SubmittedContribution> mine;
    try {
      mine = await repository.mine();
    } on ZemaFailure catch (e) {
      if (same()) {
        state = MyContributions(
          mine: state.mine,
          unseen: state.unseen,
          failure: e,
        );
      }
      return;
    }
    if (!same()) return;
    await ref.read(ownCopyReconcilerProvider).reconcile(mine);
    final store = ref.read(contributionSeenStoreProvider);
    final seen = store.read(userId);
    final since = seen.reviewedUntil;
    final reviewed = [
      for (final c in mine)
        if (c.status != ContributionStatus.pending && c.reviewedAt != null) c,
    ];
    final changed = since == null
        ? const <SubmittedContribution>[]
        : [
            for (final c in reviewed)
              if (c.reviewedAt!.isAfter(since)) c,
          ];
    var latest = since ?? ContributionSeen.firstCheck;
    for (final c in reviewed) {
      if (c.reviewedAt!.isAfter(latest)) latest = c.reviewedAt!;
    }
    final ids = {for (final c in mine) c.id};
    final next = ContributionSeen(
      reviewedUntil: latest,
      unseen: {
        for (final id in seen.unseen)
          if (ids.contains(id)) id,
        for (final c in changed) c.id,
      },
    );
    await store.write(userId, next);
    if (!same()) return;
    state = MyContributions(mine: mine, unseen: next.unseen);
    if (changed.isNotEmpty) ref.read(_changesProvider).add(changed);
  }

  /// Clears the badge (S23 was opened).
  Future<void> markSeen() async {
    final userId = ref.read(authUserProvider).value?.id;
    if (userId == null || state.unseen.isEmpty) return;
    state = MyContributions(mine: state.mine, failure: state.failure);
    final store = ref.read(contributionSeenStoreProvider);
    await store.write(
      userId,
      ContributionSeen(reviewedUntil: store.read(userId).reviewedUntil),
    );
  }
}

/// Profile's counts: lyrics added (new songs sent), synced (sent with
/// timings) and approved, of contributions not rejected.
({int lyrics, int synced, int approved}) contributionStats(
  List<SubmittedContribution> mine,
) {
  final kept = mine.where((c) => c.status != ContributionStatus.rejected);
  return (
    lyrics: kept.where((c) => c.kind == ContributionKind.newSong).length,
    synced: kept.where((c) => c.contribution.timing != null).length,
    approved: kept.where((c) => c.status == ContributionStatus.approved).length,
  );
}
