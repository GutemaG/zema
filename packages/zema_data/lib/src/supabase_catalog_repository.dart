import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

/// The catalog served by a Supabase backend (see `backend/`), through its
/// RPC functions `song_index`, `get_song`, `search_songs` and
/// `submit_report`.
///
/// Every request gives up after [timeout]. Failures are thrown as
/// [ZemaFailure]s only: [NetworkFailure], [RateLimitFailure],
/// [BackendFailure] or, for a malformed answer, [LyricsFormatFailure].
class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository({
    required String url,
    required String key,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = SupabaseClient(
         url,
         key,
         httpClient: _TimeoutClient(httpClient ?? http.Client(), timeout),
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
      'reason': _reasonNames[reason],
      'install_id': installId,
      'recording_id': ?recordingId,
      'note': ?note,
      'report_id': ?reportId,
    });
  }

  /// Releases the client's connections and background isolate.
  Future<void> close() => _client.dispose();

  Future<Object?> _call(String function, [Map<String, Object?>? params]) async {
    try {
      return await _client.rpc<Object?>(function, params: params);
    } on Object catch (e) {
      throw _failure(function, e);
    }
  }
}

const _reasonNames = {
  ReportReason.wrongWords: 'wrong_words',
  ReportReason.wrongTiming: 'wrong_timing',
  ReportReason.wrongSong: 'wrong_song',
  ReportReason.other: 'other',
};

/// The [ZemaFailure] for error [e] from calling [function].
ZemaFailure _failure(String function, Object e) => switch (e) {
  ZemaFailure() => e,
  PostgrestException(code: 'PT429') => RateLimitFailure(
    '$function: ${e.message}',
    cause: e,
  ),
  // PostgREST's JWT errors, or the gateway's 401/403 for an unknown key.
  PostgrestException(code: 'PGRST301' || 'PGRST302' || '401' || '403') =>
    BackendFailure("$function: the backend refused the app's key", cause: e),
  // The gateway is up but the API behind it isn't.
  PostgrestException(code: '502' || '503' || '504') => NetworkFailure(
    '$function: backend unavailable (${e.code})',
    cause: e,
  ),
  PostgrestException() => BackendFailure(
    '$function: ${e.code} ${e.message}',
    cause: e,
  ),
  FormatException() => BackendFailure(
    '$function: unreadable answer: $e',
    cause: e,
  ),
  // No answer from the server: offline, refused, TLS or timed out
  // (http.ClientException, TimeoutException, ...).
  _ => NetworkFailure('$function: $e', cause: e),
};

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

/// Gives up on any request that takes longer than [timeout].
class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this.timeout);

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}
