import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/detected_matches_dao.dart';
import '../../../app/database/zema_database.dart';
import '../../catalog/application/catalog_index.dart';
import '../../identify/application/listen_controller.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/data/lyrics_links_repository.dart';
import '../data/playback_detector.dart';
import 'detection_providers.dart';

final _log = Logger('detection.match');

String detectionKey(DetectedPlayback playback) {
  if (playback.mediaId case final id?) return '${playback.source}\nid:$id';
  return [
    playback.source,
    normalizeSearchText(playback.title ?? ''),
    normalizeSearchText(playback.artist ?? ''),
  ].join('\n');
}

enum DetectedHow { remembered, title }

sealed class DetectedSong {
  const DetectedSong(this.playback);

  final DetectedPlayback playback;

  String get key => detectionKey(playback);
}

class DetectedMatch extends DetectedSong {
  const DetectedMatch(
    super.playback, {
    required this.song,
    required this.how,
    this.offset = Duration.zero,
  });

  final CatalogEntry song;
  final DetectedHow how;
  final Duration offset;

  Duration positionAt(DateTime now) => playback.positionAt(now) + offset;
}

class DetectedUnsure extends DetectedSong {
  const DetectedUnsure(super.playback, {required this.candidates});

  final List<CatalogEntry> candidates;
}

class DetectedNotMezmur extends DetectedSong {
  const DetectedNotMezmur(super.playback);
}

class DetectedUnknown extends DetectedSong {
  const DetectedUnknown(super.playback);
}

final _rememberedProvider = StreamProvider<Map<String, DetectedMatchRow>>(
  (ref) => ref
      .watch(databaseProvider)
      .detectedMatchesDao
      .watchAll()
      .map((rows) => {for (final row in rows) row.sourceKey: row}),
);

final _catalogByIdProvider = Provider<Map<String, CatalogEntry>?>((ref) {
  final entries = ref.watch(catalogEntriesProvider).value;
  return entries == null ? null : {for (final e in entries) e.id: e};
});

final _matcherProvider = Provider<SongMatcher<CatalogEntry>?>((ref) {
  final entries = ref.watch(catalogEntriesProvider).value;
  return entries == null ? null : SongMatcher(entries);
});

final _titleChoiceProvider =
    Provider.family<DetectedSongChoice<CatalogEntry>?, (String, String?)>((
      ref,
      detected,
    ) {
      final matcher = ref.watch(_matcherProvider);
      if (matcher == null) return null;
      final (title, artist) = detected;
      return chooseDetectedSong(matcher.rank(title, artist: artist));
    });

final detectedSongProvider = Provider<DetectedSong?>((ref) {
  final playback = ref.watch(currentDetectionProvider);
  final title = playback?.title;
  if (playback == null || title == null) return null;
  final remembered = ref.watch(_rememberedProvider).value;
  final catalog = ref.watch(_catalogByIdProvider);
  if (remembered == null || catalog == null) return null;
  if (remembered[detectionKey(playback)] case final row?) {
    final songId = row.songId;
    if (songId == null) return DetectedNotMezmur(playback);
    if (catalog[songId] case final song?) {
      return DetectedMatch(
        playback,
        song: song,
        how: DetectedHow.remembered,
        offset: Duration(milliseconds: row.offsetMs),
      );
    }
  }
  final choice = ref.watch(_titleChoiceProvider((title, playback.artist)));
  if (choice == null) return null;
  if (choice.sure case final song?) {
    return DetectedMatch(playback, song: song, how: DetectedHow.title);
  }
  if (choice.candidates.isNotEmpty) {
    return DetectedUnsure(playback, candidates: choice.candidates);
  }
  return DetectedUnknown(playback);
});

final detectedMatchControllerProvider = Provider<DetectedMatchController>(
  (ref) => DetectedMatchController(
    ref.watch(databaseProvider).detectedMatchesDao,
    ref.watch(lyricsLinksRepositoryProvider).watchLinks,
  ),
);

class DetectedMatchController {
  const DetectedMatchController(this._dao, this._links);

  final DetectedMatchesDao _dao;
  final Stream<Map<int, LyricsLink>> Function() _links;

  Future<void> confirm(DetectedPlayback playback, SongIdentity song) =>
      _dao.remember(detectionKey(playback), song.id, at: clock.now());

  Future<void> setOffset(
    DetectedPlayback playback,
    String songId,
    Duration offset,
  ) => _dao.remember(
    detectionKey(playback),
    songId,
    offset: offset,
    at: clock.now(),
  );

  Future<void> notMezmur(DetectedPlayback playback) =>
      _dao.remember(detectionKey(playback), null, at: clock.now());

  Future<void> forget(DetectedPlayback playback) =>
      _dao.forget(detectionKey(playback));

  Future<void> clearAll() => _dao.clear();

  Future<bool> rememberListened(
    DetectedPlayback playback,
    ListenFound found,
  ) async {
    final songId = switch (found.track) {
      final track? => (await _links().first)[track.id]?.songId,
      null => found.song?.id,
    };
    if (songId == null) return false;
    final now = clock.now();
    await _dao.remember(
      detectionKey(playback),
      songId,
      offset: found.positionAt(now) - playback.positionAt(now),
      at: now,
    );
    return true;
  }
}

final listeningForProvider = NotifierProvider<ListeningFor, DetectedPlayback?>(
  ListeningFor.new,
);

class ListeningFor extends Notifier<DetectedPlayback?> {
  @override
  DetectedPlayback? build() => null;

  void set(DetectedPlayback? playback) => state = playback;
}

final listenedMatchSyncProvider = Provider<void>((ref) {
  final subscription = ref.watch(listenFoundEventsProvider).stream.listen((
    found,
  ) {
    final asked = ref.read(listeningForProvider);
    if (asked == null) return;
    ref.read(listeningForProvider.notifier).set(null);
    final now = ref.read(currentDetectionProvider);
    if (now == null || detectionKey(now) != detectionKey(asked)) return;
    unawaited(
      ref
          .read(detectedMatchControllerProvider)
          .rememberListened(now, found)
          .then<void>((_) {})
          .catchError((Object e, StackTrace s) {
            _log.warning('Could not remember the match', e, s);
          }),
    );
  });
  ref.onDispose(subscription.cancel);
});
