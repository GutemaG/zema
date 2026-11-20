import 'dart:async';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/fingerprints_dao.dart';
import '../../../app/database/zema_database.dart';
import '../../../app/preferences_provider.dart';
import '../../catalog/application/report_sender.dart';
import '../../lyrics/data/lyrics_links_repository.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../data/audio_decoder.dart';
import 'track_sound_links.dart';

final _log = Logger('identify.track_prints');

/// Shares the track prints of library files linked to a song by title or by
/// hand (intent 013, FR-4), once per song, so other phones' untagged copies
/// find it. Only prints are sent, never audio.
class TrackPrintSharer {
  TrackPrintSharer({
    required this._catalog,
    required this._decoder,
    required this._store,
    required this._links,
    required this._tracks,
    required this._installId,
  });

  final TrackPrintCatalog _catalog;
  final AudioDecoder _decoder;
  final FingerprintsDao _store;
  final Future<Map<int, LyricsLink>> Function() _links;
  final Future<List<Track>> Function() _tracks;
  final String Function() _installId;
  Future<int>? _sharing;

  /// One file for each linked song no print was shared for yet, leaving out
  /// files too short or unreadable to print.
  Future<List<Track>> needed() async {
    final links = await _links();
    final shared = await _store.sharedPrintSongs();
    final prints = await _store.trackPrintsByTrack();
    final open = <String, Track>{};
    for (final track in await _tracks()) {
      final song = links[track.id]?.songId;
      if (song == null || track.missing || shared.contains(song)) continue;
      if (track.duration < trackPrintMinOverlap) continue;
      final row = prints[track.id];
      if (row != null && _fresh(row, track) && !_usable(row)) continue;
      open.putIfAbsent(song, () => track);
    }
    return open.values.toList();
  }

  /// Shares up to [limit] prints; returns how many were sent. Stops offline
  /// and at the daily limit.
  Future<int> share({int limit = 10}) =>
      _sharing ??= _share(limit).whenComplete(() => _sharing = null);

  Future<int> _share(int limit) async {
    final links = await _links();
    var sent = 0;
    for (final track in (await needed()).take(limit)) {
      final song = links[track.id]!.songId!;
      final row = await _store.trackPrint(track.id);
      final fresh = row != null && _fresh(row, track);
      final print = fresh
          ? TrackPrint.fromBytes(row.print)
          : await _printOf(track);
      final usable =
          print != null && print.values.length >= trackPrintMinValues;
      var done = false;
      if (usable) {
        try {
          await _catalog.shareTrackPrint(song, print, installId: _installId());
          sent++;
          done = true;
        } on NetworkFailure {
          return sent;
        } on RateLimitFailure {
          return sent;
        } on ZemaFailure catch (e) {
          // Refused (say, a different length): sending again won't help.
          _log.warning('Print of track ${track.id} refused', e);
          done = true;
        }
      }
      await _store.putTrackPrint(
        TrackPrintsCompanion.insert(
          trackId: Value(track.id),
          sizeBytes: track.sizeBytes,
          version: trackPrintVersion,
          print:
              (print ??
                      TrackPrint(
                        values: Uint32List(0),
                        duration: track.duration,
                      ))
                  .toBytes(),
          songId: Value(fresh ? row.songId : null),
          lookedUp: fresh && row.lookedUp,
          sharedSongId: Value(done ? song : null),
          checkedAt: clock.now().toUtc(),
        ),
      );
    }
    return sent;
  }

  Future<TrackPrint?> _printOf(Track track) async {
    final audio = await _decoder.decode(track.uri, maxLength: linkDecodeLength);
    if (audio == null) return null;
    return trackPrintOf(pcm16ToFloat(audio.pcm16), track.duration);
  }

  static bool _fresh(TrackPrintRow row, Track track) =>
      row.sizeBytes == track.sizeBytes && row.version == trackPrintVersion;

  /// Whether [row]'s print is long enough to send (an empty one marks a
  /// file too short or unreadable).
  static bool _usable(TrackPrintRow row) =>
      TrackPrint.fromBytes(row.print).values.length >= trackPrintMinValues;
}

final trackPrintSharerProvider = Provider<TrackPrintSharer?>((ref) {
  final catalog = ref.watch(trackPrintCatalogProvider);
  if (catalog == null) return null;
  final db = ref.watch(databaseProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  return TrackPrintSharer(
    catalog: catalog,
    decoder: ref.watch(audioDecoderProvider),
    store: db.fingerprintsDao,
    links: () => ref.read(lyricsLinksRepositoryProvider).watchLinks().first,
    tracks: db.libraryDao.allTracks,
    installId: () => installId(preferences),
  );
});
