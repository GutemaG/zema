import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../shared/combine_async.dart';
import '../../player/application/player_providers.dart';
import '../data/history_repository.dart';
import 'library_providers.dart';

final _log = Logger('library.history');

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(databaseProvider).historyDao),
);

/// Prunes old plays once at start, then stores every play the player
/// counts. Kept alive by the app shell.
final playHistoryProvider = Provider<void>((ref) {
  final history = ref.watch(historyRepositoryProvider);
  final handler = ref.watch(audioHandlerProvider);

  Future<void> guarded(Future<void> Function() write, String what) async {
    try {
      await write();
    } on ZemaFailure catch (failure) {
      _log.warning('Could not $what', failure, null);
    }
  }

  unawaited(guarded(history.prune, 'prune play history'));
  final subscription = handler.playCounted.listen(
    (track) =>
        unawaited(guarded(() => history.recordPlay(track.id), 'record a play')),
  );
  ref.onDispose(() => unawaited(subscription.cancel()));
});

/// The read-only playlists Zema keeps by itself.
enum AutoPlaylistKind {
  /// Added in the last [recentlyAddedWindow], newest first.
  recentlyAdded,

  /// The [autoPlaylistLimit] songs played most.
  mostPlayed,

  /// The last [autoPlaylistLimit] songs played, newest first.
  recentlyPlayed,
}

const recentlyAddedWindow = Duration(days: 30);
const autoPlaylistLimit = 50;

final _mostPlayedIdsProvider = StreamProvider<List<int>>(
  (ref) => ref.watch(historyRepositoryProvider).watchMostPlayed(),
);

final _recentlyPlayedIdsProvider = StreamProvider<List<int>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecentlyPlayed(),
);

/// The songs in an auto playlist. Like every list, only visible songs:
/// hidden, missing and too-short ones are left out before the
/// [autoPlaylistLimit] is applied, so they don't take places.
final autoPlaylistProvider =
    Provider.family<AsyncValue<List<Track>>, AutoPlaylistKind>((ref, kind) {
      final tracks = ref.watch(libraryTracksProvider);
      return switch (kind) {
        AutoPlaylistKind.recentlyAdded => tracks.whenData(recentlyAdded),
        AutoPlaylistKind.mostPlayed => combineAsync(
          ref.watch(_mostPlayedIdsProvider),
          tracks,
          _visibleInOrder,
        ),
        AutoPlaylistKind.recentlyPlayed => combineAsync(
          ref.watch(_recentlyPlayedIdsProvider),
          tracks,
          _visibleInOrder,
        ),
      };
    });

/// [tracks] added in the last [recentlyAddedWindow], newest first.
List<Track> recentlyAdded(List<Track> tracks) {
  final since = clock.now().subtract(recentlyAddedWindow);
  return tracks.where((t) => !t.dateAdded.isBefore(since)).toList()
    ..sort((a, b) {
      final byDate = b.dateAdded.compareTo(a.dateAdded);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
}

List<Track> _visibleInOrder(List<int> ids, List<Track> tracks) {
  final byId = {for (final t in tracks) t.id: t};
  return [for (final id in ids) ?byId[id]].take(autoPlaylistLimit).toList();
}
