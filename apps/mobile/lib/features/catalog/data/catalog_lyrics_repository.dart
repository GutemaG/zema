import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/cached_songs_dao.dart';
import '../../../app/database/catalog_dao.dart';
import '../../../app/database/database_provider.dart';

final _log = Logger('catalog.lyrics');

/// The lyrics the app reads: the catalog's songs, cached on the phone.
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CatalogLyricsRepository(
    catalog: ref.watch(catalogRepositoryProvider),
    index: db.catalogDao,
    cache: db.cachedSongsDao,
  );
});

/// Lyrics from the cloud catalog, downloaded the first time a song is
/// needed and read from the phone after that.
///
/// A song the index doesn't list counts as missing. A cached copy older
/// than the index's version is fetched again; if that fails, the old copy
/// is used. A song that was never cached and can't be fetched throws the
/// [ZemaFailure] (usually a [NetworkFailure]). Everything but [song] reads
/// the cache only.
class CatalogLyricsRepository implements LyricsRepository {
  CatalogLyricsRepository({
    required this._catalog,
    required this._index,
    required this._cache,
  });

  final CatalogRepository? _catalog;
  final CatalogDao _index;
  final CachedSongsDao _cache;

  /// Documents already read or fetched, so repeat reads skip Drift.
  final _read = <String, CachedSong>{};
  final _fetching = <String, Future<SongDocument?>>{};

  /// The song [id]'s document: cached, or fetched and saved.
  Future<SongDocument?> document(String id) async {
    final entry = await _index.entry(id);
    if (entry == null) return null;
    final known = _read[id] ?? await _cache.song(id);
    if (known != null && known.version >= entry.version) {
      _read[id] = known;
      return known.document;
    }
    // A block body: returning the removed future from whenComplete would
    // make it wait for itself.
    return _fetching[id] ??= _fetch(entry, known).whenComplete(() {
      _fetching.remove(id);
    });
  }

  Future<SongDocument?> _fetch(CatalogEntry entry, CachedSong? old) async {
    try {
      final catalog = _catalog;
      if (catalog == null) {
        throw const NetworkFailure('This build has no lyrics catalog');
      }
      final document = await catalog.song(entry.id);
      if (document == null) return null;
      await _cache.save(document, entry.version);
      _read[entry.id] = (document: document, version: entry.version);
      return document;
    } on ZemaFailure catch (e) {
      if (old == null) rethrow;
      _log.info('Showing the cached ${entry.id}: ${e.message}');
      return old.document;
    }
  }

  /// The cached documents of songs the index still lists.
  Future<List<SongDocument>> _cached() async {
    final listed = {for (final e in await _index.watchEntries().first) e.id};
    return [
      for (final cached in await _cache.watchSongs().first)
        if (listed.contains(cached.document.song.id)) cached.document,
    ];
  }

  @override
  Future<Song?> song(String id) async => (await document(id))?.song;

  @override
  Future<List<Song>> songs() async => [
    for (final document in await _cached()) document.song,
  ];

  @override
  Future<List<Recording>> recordings(String songId) async =>
      (_read[songId] ?? await _cache.song(songId))?.document.recordings ??
      const [];

  @override
  Future<SyncTiming?> timing(String recordingId) async {
    for (final known in _read.values) {
      if (_timingIn(known.document, recordingId) case final timing?) {
        return timing;
      }
    }
    for (final document in await _cached()) {
      if (_timingIn(document, recordingId) case final timing?) return timing;
    }
    return null;
  }

  @override
  Future<List<Song>> search(String query) async =>
      searchSongs(await songs(), query);
}

SyncTiming? _timingIn(SongDocument document, String recordingId) =>
    document.timings.where((t) => t.recordingId == recordingId).firstOrNull;
