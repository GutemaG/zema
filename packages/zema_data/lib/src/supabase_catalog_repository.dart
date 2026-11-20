import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

import 'backend_errors.dart';

/// The catalog served by a Supabase backend (see `backend/`), through its
/// RPC functions `song_index`, `get_song`, `search_songs`, `submit_report`,
/// `identify_audio`, `missing_fingerprints`, `share_fingerprint`,
/// `offline_fingerprints` and `get_fingerprints`.
///
/// Every request gives up after [timeout]. Failures are thrown as
/// [ZemaFailure]s only: [NetworkFailure], [RateLimitFailure],
/// [BackendFailure] or, for a malformed answer, [LyricsFormatFailure].
class SupabaseCatalogRepository
    implements CatalogRepository, AudioCatalog, TrackPrintCatalog {
  SupabaseCatalogRepository({
    required String url,
    required String key,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = SupabaseClient(
         url,
         key,
         httpClient: TimeoutClient(httpClient ?? http.Client(), timeout),
         authOptions: const AuthClientOptions(autoRefreshToken: false),
       );

  final SupabaseClient _client;

  @override
  Future<List<CatalogEntry>> index() async {
    final rows = await _call('song_index');
    return _parse(() => [for (final row in _rows(rows)) _entry(row)]);
  }

  @override
  Future<SongDocument?> song(String id) async {
    final document = await _call('get_song', {'song_id': id});
    if (document == null) return null;
    return _parse(() => SongDocument.fromJson(document));
  }

  @override
  Future<List<CatalogSearchHit>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final rows = await _call('search_songs', {'query': query});
    return _parse(() => [for (final row in _rows(rows)) _hit(row)]);
  }

  @override
  Future<void> report({
    required String songId,
    required ReportReason reason,
    required String installId,
    String? recordingId,
    String? note,
    String? reportId,
  }) async {
    await _call('submit_report', {
      'song_id': songId,
      'reason': reportReasonWire[reason],
      'install_id': installId,
      'recording_id': ?recordingId,
      'note': ?note,
      'report_id': ?reportId,
    });
  }

  @override
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  }) async {
    if (queries.every((q) => q.length == 0)) return const [];
    final rows = await _call('identify_audio', {
      'version': fingerprintVersion,
      'install_id': installId,
      'hashes': [for (final q in queries) ...q.hashes],
      'frames': [for (final q in queries) ...q.frames],
      'queries': [
        for (final (i, q) in queries.indexed) ...List.filled(q.length, i),
      ],
      'max_results': limit,
    });
    return _parse(
      () => [for (final row in _rows(rows)) _audioMatch(row, queries)],
    );
  }

  @override
  Future<List<OfflineFingerprintEntry>> offlineFingerprints() async {
    final rows = await _call('offline_fingerprints', {
      'version': fingerprintVersion,
    });
    return _parse(
      () => [
        for (final row in _rows(rows))
          OfflineFingerprintEntry(
            recordingId: row['recording_id']! as String,
            songId: row['song_id']! as String,
            revision: row['revision']! as int,
            hashCount: row['hash_count']! as int,
            identified: row['identified']! as int,
          ),
      ],
    );
  }

  @override
  Future<List<CatalogFingerprint>> fingerprints(
    List<String> recordingIds,
  ) async {
    if (recordingIds.isEmpty) return const [];
    final rows = await _call('get_fingerprints', {
      'version': fingerprintVersion,
      'ids': recordingIds.take(20).toList(),
    });
    return _parse(
      () => [
        for (final row in _rows(rows))
          CatalogFingerprint(
            recordingId: row['recording_id']! as String,
            revision: row['revision']! as int,
            fingerprint: AudioFingerprint(
              hashes: Uint32List.fromList(
                (row['hashes']! as List<Object?>).cast<int>(),
              ),
              frames: Uint32List.fromList(
                (row['frames']! as List<Object?>).cast<int>(),
              ),
              frameCount: row['frame_count']! as int,
            ),
          ),
      ],
    );
  }

  @override
  Future<Set<String>> missingFingerprints(List<String> recordingIds) async {
    if (recordingIds.isEmpty) return const {};
    final rows = await _call('missing_fingerprints', {
      'version': fingerprintVersion,
      'ids': recordingIds.take(200).toList(),
    });
    return _parse(
      () => {for (final id in rows! as List<Object?>) id! as String},
    );
  }

  @override
  Future<FingerprintShare> shareFingerprint(
    String recordingId,
    AudioFingerprint fingerprint, {
    required String installId,
  }) async {
    final answer = await _call('share_fingerprint', {
      'recording': recordingId,
      'version': fingerprintVersion,
      'frame_count': fingerprint.frameCount,
      'hashes': fingerprint.hashes,
      'frames': fingerprint.frames,
      'install_id': installId,
    });
    return switch (answer) {
      'pending' => FingerprintShare.pending,
      'published' => FingerprintShare.published,
      'not_needed' => FingerprintShare.notNeeded,
      _ => throw LyricsFormatFailure('Unexpected share answer: $answer'),
    };
  }

  @override
  Future<List<TrackPrintMatch>> matchTrack(
    TrackPrint print, {
    required String installId,
    int limit = 3,
  }) async {
    final rows = await _call('match_track', {
      'version': trackPrintVersion,
      'print': printValuesSigned(print),
      'duration_ms': print.duration.inMilliseconds,
      'install_id': installId,
      'max_results': limit,
    });
    return _parse(
      () => [
        for (final row in _rows(rows))
          (
            songId: row['song_id']! as String,
            bits: (row['bits']! as num).toDouble(),
          ),
      ],
    );
  }

  @override
  Future<FingerprintShare> shareTrackPrint(
    String songId,
    TrackPrint print, {
    required String installId,
  }) async {
    final answer = await _call('share_track_print', {
      'song': songId,
      'version': trackPrintVersion,
      'print': printValuesSigned(print),
      'duration_ms': print.duration.inMilliseconds,
      'install_id': installId,
    });
    return switch (answer) {
      'pending' => FingerprintShare.pending,
      'published' => FingerprintShare.published,
      'not_needed' => FingerprintShare.notNeeded,
      _ => throw LyricsFormatFailure('Unexpected share answer: $answer'),
    };
  }

  /// Releases the client's connections and background isolate.
  Future<void> close() => _client.dispose();

  Future<Object?> _call(String function, [Map<String, Object?>? params]) async {
    try {
      return await _client.rpc<Object?>(function, params: params);
    } on Object catch (e) {
      throw backendFailure(function, e);
    }
  }
}

T _parse<T>(T Function() parse) {
  try {
    return parse();
  } on LyricsFormatFailure {
    rethrow;
  } on Object catch (e) {
    throw LyricsFormatFailure('Malformed catalog response: $e', cause: e);
  }
}

List<Map<String, Object?>> _rows(Object? json) => switch (json) {
  final List<Object?> rows => [
    for (final row in rows)
      row is Map
          ? row.cast<String, Object?>()
          : throw const LyricsFormatFailure('A catalog row must be an object'),
  ],
  _ => throw const LyricsFormatFailure('A catalog response must be a list'),
};

CatalogEntry _entry(Map<String, Object?> row) => CatalogEntry(
  id: row['id']! as String,
  title: row['title']! as String,
  transliteration: row['transliteration'] as String?,
  artist: row['artist'] as String?,
  album: row['album'] as String?,
  synced: row['synced']! as bool,
  version: row['version']! as int,
  approvedAt: DateTime.parse(row['approved_at']! as String),
);

CatalogSearchHit _hit(Map<String, Object?> row) => CatalogSearchHit(
  songId: row['song_id']! as String,
  title: row['title']! as String,
  transliteration: row['transliteration'] as String?,
  artist: row['artist'] as String?,
  score: (row['score']! as num).toDouble(),
  line: row['line_text'] as String?,
  lineTransliteration: row['line_transliteration'] as String?,
);

CatalogAudioMatch _audioMatch(
  Map<String, Object?> row,
  List<AudioFingerprint> queries,
) => CatalogAudioMatch(
  songId: row['song_id']! as String,
  recordingDuration: fingerprintFrameTime(row['frame_count']! as int),
  match: audioMatchAt(
    recordingId: row['recording_id']! as String,
    shift: row['shift']! as int,
    score: row['score']! as int,
    runnerUp: row['runner_up']! as int,
    speed: queries[row['query']! as int].speed,
  ),
);
