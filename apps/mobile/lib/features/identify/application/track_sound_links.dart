import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/fingerprints_dao.dart';
import '../../../app/database/zema_database.dart';
import '../../../app/preferences_provider.dart';
import '../../catalog/application/report_sender.dart';
import '../../library/application/library_providers.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/data/lyrics_links_repository.dart';
import '../../player/application/player_providers.dart';
import '../data/audio_decoder.dart';
import 'library_fingerprints.dart';
import 'library_search.dart';

final _log = Logger('identify.sound_links');

/// What a library file is, by its sound: a catalog song, the recording it
/// lined up with when known, and how much later the file runs than it.
typedef SoundMatch = ({String songId, String? recordingId, Duration offset});

/// The phone's fingerprints, searchable by excerpt ([LibrarySearch]).
abstract interface class SoundSearch {
  int get recordingCount;

  /// The catalog recordings searched, by recording ID.
  Map<String, OfflineRecording> get catalogRecordings;

  Future<LibraryHeard> identify(
    Float32List pcm,
    int rate, {
    String? exclude,
    int limit,
  });
}

/// How much of a file its two excerpts are taken from.
const soundDecodeLength = Duration(seconds: 105);

/// How much of a file is decoded to identify it: enough for the excerpts
/// and the track print.
const linkDecodeLength = trackPrintLength;

/// How long lookups of track prints wait after the server couldn't be
/// reached or said no more today.
const printLookupPause = Duration(minutes: 30);

/// How long each excerpt is.
const soundExcerptLength = Duration(seconds: 12);

/// How far apart two excerpts' offsets may be and still count as one.
const soundOffsetTolerance = Duration(milliseconds: 250);

/// Where the two excerpts start in a file whose first [length] was
/// decoded: about a quarter in (at most 30 s, past most intros) and near
/// the end of what was decoded (at most 90 s). None under 30 s.
List<Duration> soundExcerptStarts(Duration length) {
  if (length < const Duration(seconds: 30)) return const [];
  Duration atMost(Duration a, Duration b) => a < b ? a : b;
  return [
    atMost(length * 0.25, const Duration(seconds: 30)),
    atMost(
      length - soundExcerptLength - const Duration(milliseconds: 500),
      const Duration(seconds: 90),
    ),
  ];
}

/// The match both excerpts agree on: the same song, and the first's offset
/// when the offsets agree too (a repeated chorus can line up elsewhere),
/// else none (as a title match assumes). Null when they disagree or either
/// found nothing.
SoundMatch? agreedMatch(SoundMatch? a, SoundMatch? b) {
  if (a == null || b == null || a.songId != b.songId) return null;
  final same = (a.offset - b.offset).abs() <= soundOffsetTolerance;
  return (
    songId: a.songId,
    recordingId: same ? (a.recordingId ?? b.recordingId) : null,
    offset: same ? a.offset : Duration.zero,
  );
}

/// Whether [track] should be identified by sound again, given its last
/// result [row], the [searched] recordings on the phone now, and whether
/// the server may be asked.
bool needsSoundCheck(
  Track track,
  TrackAudioMatchRow? row, {
  required int searched,
  required bool server,
}) {
  if (row == null || row.sizeBytes != track.sizeBytes) return true;
  if (row.songId != null) return false;
  return row.searched != searched || (server && !row.askedServer);
}

/// Whether [track]'s track print should be made ([row] is none, or for
/// another file or version) or looked up again ([server] may be asked and
/// it wasn't answered yet).
bool needsPrintCheck(Track track, TrackPrintRow? row, {required bool server}) {
  if (row == null ||
      row.sizeBytes != track.sizeBytes ||
      row.version != trackPrintVersion) {
    return true;
  }
  return server && !row.lookedUp;
}

/// [track]'s track print of its decoded start [pcm] (at
/// [fingerprintSampleRate]), made off the UI isolate.
Future<TrackPrint> trackPrintOf(Float32List pcm, Duration duration) {
  final moved = TransferableTypedData.fromList([pcm]);
  return Isolate.run(
    () => const TrackPrinter().print(
      moved.materialize().asFloat32List(),
      duration: duration,
    ),
  );
}

/// Identifies library files by their sound (intent 009): two excerpts are
/// searched among the phone's fingerprints (the library's and the catalog's
/// kept offline), then, if allowed, on the server, which stores nothing.
/// A library file that matches lends its song. Results are saved.
///
/// When that finds nothing, the file's track print (intent 013) is looked
/// up in the catalog's [TrackPrintCatalog]: in the background too, once per
/// file, waiting while offline. The print is kept for sharing.
class SoundLinker {
  SoundLinker({
    required this._decoder,
    required this._search,
    required this._store,
    required this._links,
    this._catalog,
    this._prints,
    this._installId,
  });

  final AudioDecoder _decoder;
  final Future<SoundSearch> Function() _search;
  final FingerprintsDao _store;
  final Future<Map<int, LyricsLink>> Function() _links;
  final AudioCatalog? _catalog;
  final TrackPrintCatalog? _prints;
  final String Function()? _installId;
  DateTime? _printsPausedUntil;

  bool get _askPrints =>
      _prints != null &&
      _installId != null &&
      !(_printsPausedUntil?.isAfter(clock.now()) ?? false);

  /// Identifies [track] if it needs it (see [needsSoundCheck]); [server]
  /// allows asking the catalog when the phone finds nothing. Returns the
  /// match, or null.
  Future<SoundMatch?> check(Track track, {bool server = false}) async {
    final search = await _search();
    final asking = server && _catalog != null;
    final row = await _store.audioMatch(track.id);
    final soundDue = needsSoundCheck(
      track,
      row,
      searched: search.recordingCount,
      server: asking,
    );
    final known = soundDue ? null : _matchOf(row);
    if (known != null) return known;
    final printRow = await _store.trackPrint(track.id);
    final printDue = needsPrintCheck(track, printRow, server: _askPrints);
    if (!soundDue && !printDue) return null;
    if (!soundDue && printRow != null && _printFresh(printRow, track)) {
      await _checkPrint(track, null, printRow);
      return null;
    }
    final audio = await _decoder.decode(track.uri, maxLength: linkDecodeLength);
    final pcm = audio == null ? null : pcm16ToFloat(audio.pcm16);
    if (!soundDue) {
      await _checkPrint(track, pcm, printRow);
      return null;
    }
    final decoded = pcm == null
        ? Duration.zero
        : Duration(microseconds: pcm.length * 1000000 ~/ fingerprintSampleRate);
    final starts = pcm == null
        ? const <Duration>[]
        : soundExcerptStarts(
            decoded < soundDecodeLength ? decoded : soundDecodeLength,
          );
    final heard = <(Duration, LibraryHeard)>[];
    for (final start in starts) {
      final from = start.inMicroseconds * fingerprintSampleRate ~/ 1000000;
      final to =
          from +
          soundExcerptLength.inMicroseconds * fingerprintSampleRate ~/ 1000000;
      heard.add((
        start,
        await search.identify(
          pcm!.sublist(from, to),
          fingerprintSampleRate,
          exclude: '${track.id}',
          limit: 3,
        ),
      ));
    }
    var match = heard.length < 2
        ? null
        : await _onPhone(search, heard[0], heard[1]);
    var askedServer = false;
    if (match == null && asking && heard.length == 2) {
      try {
        match = agreedMatch(
          await _onServer(heard[0]),
          await _onServer(heard[1]),
        );
        askedServer = true;
      } on ZemaFailure catch (e) {
        // Offline or past the daily limit: asked again next time.
        _log.info('Server not asked for track ${track.id}: $e');
      }
    }
    await _store.putAudioMatch(
      TrackAudioMatchesCompanion.insert(
        trackId: Value(track.id),
        sizeBytes: track.sizeBytes,
        songId: Value(match?.songId),
        recordingId: Value(match?.recordingId),
        offsetMs: Value(match?.offset.inMilliseconds ?? 0),
        searched: search.recordingCount,
        askedServer: askedServer,
        checkedAt: clock.now().toUtc(),
      ),
    );
    if (match == null && printDue) await _checkPrint(track, pcm, printRow);
    return match;
  }

  /// Makes [track]'s print from [pcm] (or keeps [row]'s) and looks it up
  /// when the server may be asked. Saves the result.
  Future<void> _checkPrint(
    Track track,
    Float32List? pcm,
    TrackPrintRow? row,
  ) async {
    final fresh = row != null && _printFresh(row, track);
    final print = fresh
        ? TrackPrint.fromBytes(row.print)
        : pcm == null
        ? TrackPrint(values: Uint32List(0), duration: track.duration)
        : await trackPrintOf(pcm, track.duration);
    final usable =
        print.values.length >= trackPrintMinValues &&
        print.duration >= trackPrintMinOverlap;
    var lookedUp = !usable || (fresh && row.lookedUp);
    var songId = fresh ? row.songId : null;
    if (!lookedUp && _askPrints) {
      try {
        final found = await _prints!.matchTrack(
          print,
          installId: _installId!(),
          limit: 1,
        );
        songId = found.firstOrNull?.songId;
        lookedUp = true;
      } on NetworkFailure catch (e) {
        _pausePrints(track, e);
      } on RateLimitFailure catch (e) {
        _pausePrints(track, e);
      } on ZemaFailure catch (e) {
        // Refused: asking again won't change the answer.
        _log.warning('Print of track ${track.id} refused', e);
        lookedUp = true;
      }
    }
    await _store.putTrackPrint(
      TrackPrintsCompanion.insert(
        trackId: Value(track.id),
        sizeBytes: track.sizeBytes,
        version: trackPrintVersion,
        print: print.toBytes(),
        songId: Value(songId),
        lookedUp: lookedUp,
        sharedSongId: Value(fresh ? row.sharedSongId : null),
        checkedAt: clock.now().toUtc(),
      ),
    );
  }

  static bool _printFresh(TrackPrintRow row, Track track) =>
      row.sizeBytes == track.sizeBytes && row.version == trackPrintVersion;

  void _pausePrints(Track track, ZemaFailure e) {
    _log.info('Print of track ${track.id} not looked up: $e');
    _printsPausedUntil = clock.now().add(printLookupPause);
  }

  Future<SoundMatch?> _onPhone(
    SoundSearch search,
    (Duration, LibraryHeard) a,
    (Duration, LibraryHeard) b,
  ) async {
    final links = await _links();
    final sounds = await _store.watchAudioMatches().first;

    SoundMatch? resolve(Duration start, AudioMatch m) {
      final offset = start - m.position;
      final id = m.recordingId;
      if (id.startsWith(catalogSearchPrefix)) {
        final recording = id.substring(catalogSearchPrefix.length);
        return switch (search.catalogRecordings[recording]) {
          final r? => (
            songId: r.songId,
            recordingId: recording,
            offset: offset,
          ),
          null => null,
        };
      }
      final other = int.tryParse(id);
      if (other == null) return null;
      final link = links[other];
      if (link != null && link.manual) {
        return switch (link.songId) {
          final song? => (songId: song, recordingId: null, offset: offset),
          null => null,
        };
      }
      if (_matchOf(sounds[other]) case final sound?) {
        return (
          songId: sound.songId,
          recordingId: sound.recordingId,
          offset: offset + sound.offset,
        );
      }
      return switch (link?.songId) {
        final song? => (songId: song, recordingId: null, offset: offset),
        null => null,
      };
    }

    SoundMatch? best((Duration, LibraryHeard) heard) {
      final (start, result) = heard;
      for (final m in result.matches) {
        if (resolve(start, m) case final found?) return found;
      }
      return null;
    }

    return agreedMatch(best(a), best(b));
  }

  Future<SoundMatch?> _onServer((Duration, LibraryHeard) heard) async {
    final (start, result) = heard;
    final found = await _catalog!.identify(
      result.queries,
      installId: _installId!(),
      limit: 1,
    );
    return switch (found.firstOrNull) {
      final c? => (
        songId: c.songId,
        recordingId: c.match.recordingId,
        offset: start - c.match.position,
      ),
      null => null,
    };
  }
}

SoundMatch? _matchOf(TrackAudioMatchRow? row) => switch (row?.songId) {
  final song? => (
    songId: song,
    recordingId: row!.recordingId,
    offset: Duration(milliseconds: row.offsetMs),
  ),
  null => null,
};

/// What library files were identified as by their sound, by track ID.
final trackAudioMatchesProvider = StreamProvider<Map<int, TrackAudioMatchRow>>(
  (ref) => ref.watch(databaseProvider).fingerprintsDao.watchAudioMatches(),
);

/// [trackId]'s match by sound, when it decides the track's lyrics: there
/// is one, and the user hasn't linked the track by hand.
final trackSoundMatchProvider = Provider.family<SoundMatch?, int>((
  ref,
  trackId,
) {
  final link = ref.watch(lyricsLinksProvider).value?[trackId];
  if (link != null && link.manual) return null;
  return _matchOf(ref.watch(trackAudioMatchesProvider).value?[trackId]);
});

/// The track being identified by sound while it plays, for its "No lyrics"
/// state.
final identifyingTrackProvider = NotifierProvider<IdentifyingTrack, int?>(
  IdentifyingTrack.new,
);

class IdentifyingTrack extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? trackId) => state = trackId;
}

/// Opens the phone's search when needed, again when its fingerprints
/// change, and closes it after a minute unused.
class _SearchHolder {
  _SearchHolder(this._db);

  final ZemaDatabase _db;
  LibrarySearch? _search;
  Object? _stamp;
  Future<LibrarySearch>? _opening;
  Timer? _idle;

  Future<Object> _currentStamp() async => (
    await _db.fingerprintsDao.stamp(),
    await _db.fingerprintsDao.catalogStamp(),
  );

  Future<SoundSearch> get() async {
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 1), close);
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<LibrarySearch> _open() async {
    final stamp = await _currentStamp();
    if (_search case final current? when stamp == _stamp) return current;
    final fresh = await LibrarySearch.open(_db);
    _search?.close();
    _search = fresh;
    _stamp = stamp;
    return fresh;
  }

  void close() {
    _idle?.cancel();
    _search?.close();
    _search = null;
  }
}

final soundLinkerProvider = Provider<SoundLinker>((ref) {
  final db = ref.watch(databaseProvider);
  final holder = _SearchHolder(db);
  ref.onDispose(holder.close);
  final SharedPreferences preferences = ref.watch(sharedPreferencesProvider);
  return SoundLinker(
    decoder: ref.watch(audioDecoderProvider),
    search: holder.get,
    store: db.fingerprintsDao,
    links: () => ref.read(lyricsLinksRepositoryProvider).watchLinks().first,
    catalog: ref.watch(audioCatalogProvider),
    prints: ref.watch(trackPrintCatalogProvider),
    installId: () => installId(preferences),
  );
});

/// What library files' track prints matched, by track ID.
final trackPrintMatchesProvider = StreamProvider<Map<int, String>>(
  (ref) => ref.watch(databaseProvider).fingerprintsDao.watchTrackPrintMatches(),
);

/// The song [trackId]'s track print matched, when it decides the track's
/// lyrics: the track has no link at all (by hand or by title).
final trackPrintMatchProvider = Provider.family<String?, int>((ref, trackId) {
  final links = ref.watch(lyricsLinksProvider).value;
  if (links == null || links.containsKey(trackId)) return null;
  return ref.watch(trackPrintMatchesProvider).value?[trackId];
});

/// Whether [link] leaves the track to be identified by sound: no manual
/// choice and no title match.
bool _unlinked(LyricsLink? link) => link == null;

/// Identifies library files with no lyrics by their sound: the one being
/// played at once (asking the server too), and the others in the
/// background on the phone only, after the library is fingerprinted. Kept
/// alive by the app shell.
final soundLinkSyncProvider = Provider<void>((ref) {
  final linker = ref.watch(soundLinkerProvider);
  var closed = false;
  ref.onDispose(() => closed = true);
  Future<void> queue = Future.value();

  Future<void> run(Future<void> Function() work) => queue = queue
      .then((_) => closed ? null : work())
      .catchError(
        (Object e, StackTrace s) =>
            _log.warning('Identifying by sound failed', e, s),
      );

  Future<Map<int, LyricsLink>> links() =>
      ref.read(lyricsLinksRepositoryProvider).watchLinks().first;

  void played(Track? track) {
    if (track == null || track.missing) return;
    unawaited(
      run(() async {
        if (!_unlinked((await links())[track.id])) return;
        ref.read(identifyingTrackProvider.notifier).set(track.id);
        try {
          await linker.check(track, server: true);
        } finally {
          if (!closed && ref.read(identifyingTrackProvider) == track.id) {
            ref.read(identifyingTrackProvider.notifier).set(null);
          }
        }
      }),
    );
  }

  Future<void> pass() async {
    final tracks = await ref.read(libraryTracksProvider.future);
    final current = await links();
    for (final track in tracks) {
      if (closed) return;
      if (track.missing || !_unlinked(current[track.id])) continue;
      await linker.check(track);
      await Future<void>.delayed(songPause);
    }
  }

  ref.listen(currentTrackProvider, (previous, next) {
    if (next?.id != previous?.id) played(next);
  });
  ref.listen(libraryFingerprintsProvider, (previous, next) {
    if (previous?.running == true && !next.running) unawaited(run(pass));
  });
  unawaited(
    Future(() async {
      await ref.read(libraryFingerprintsProvider.notifier).start();
      if (!closed) await run(pass);
    }).catchError(
      (Object e, StackTrace s) =>
          _log.warning('Identifying by sound failed', e, s),
    ),
  );
});
