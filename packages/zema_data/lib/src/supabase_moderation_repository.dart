import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

import 'supabase_auth_repository.dart';

/// Reports and hidden songs through the backend's moderator functions:
/// `moderator_reports`, `resolve_report`, `moderator_songs`,
/// `moderator_song` and `set_song_hidden`. A refusal the backend names (`not_moderator`,
/// `unknown_report`, `unknown_song`, ...) becomes a [ContributionFailure]
/// with that code.
class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this._auth);

  final SupabaseAuthRepository _auth;

  @override
  Future<List<ModeratorReport>> reports(
    ReportStatus? status, {
    int limit = 100,
    int offset = 0,
  }) => _rows(
    'moderator_reports',
    {'only_status': status?.wire, 'max_rows': limit, 'skip': offset},
    (row) => ModeratorReport(
      id: _string(row['id']),
      songId: row['song_id'] as String?,
      songTitle: row['song_title'] as String?,
      recordingId: row['recording_id'] as String?,
      reason: reportReasonWire.entries
          .firstWhere(
            (e) => e.value == row['reason'],
            orElse: () => const MapEntry(ReportReason.other, 'other'),
          )
          .key,
      note: row['note'] as String?,
      status:
          ReportStatus.fromWire(_string(row['status'])) ?? ReportStatus.open,
      createdAt: _time(row['created_at']),
    ),
  );

  @override
  Future<void> resolveReport(String id, ReportStatus status) => _run(
    'resolve_report',
    (client) => client.rpc<void>(
      'resolve_report',
      params: {'id': id, 'status': status.wire},
    ),
  );

  @override
  Future<List<ModeratedSong>> songs({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) => _rows(
    'moderator_songs',
    {'query': query, 'max_rows': limit, 'skip': offset},
    (row) => ModeratedSong(
      id: _string(row['id']),
      title: _string(row['title']),
      artist: row['artist'] as String?,
      hidden: row['status'] == 'hidden',
      version: row['version']! as int,
      lineCount: row['line_count']! as int,
      updatedAt: _time(row['updated_at']),
    ),
  );

  @override
  Future<SongDocument?> song(String id) => _run(
    'moderator_song',
    (client) async => switch (await client.rpc<Object?>(
      'moderator_song',
      params: {'id': id},
    )) {
      null => null,
      final document => SongDocument.fromJson(document),
    },
  );

  @override
  Future<void> setHidden(String id, {required bool hidden}) => _run(
    'set_song_hidden',
    (client) => client.rpc<Object?>(
      'set_song_hidden',
      params: {'id': id, 'hidden': hidden},
    ),
  );

  Future<List<T>> _rows<T>(
    String function,
    Map<String, Object?> params,
    T Function(Map<String, dynamic> row) read,
  ) => _run(function, (client) async {
    final rows = await client.rpc<List<dynamic>>(function, params: params);
    return [for (final row in rows.cast<Map<String, dynamic>>()) read(row)];
  });

  Future<T> _run<T>(String function, Future<T> Function(SupabaseClient) call) =>
      _auth.run(function, (client, _) async {
        try {
          return await call(client);
        } on PostgrestException catch (e) {
          final code = e.message;
          if (code == 'not_signed_in') {
            throw AuthFailure('$function: not signed in', cause: e);
          }
          if (e.code == '22023' || e.code == '42501') {
            throw ContributionFailure('$function: $code', code: code, cause: e);
          }
          rethrow;
        }
      });
}

String _string(Object? value) => switch (value) {
  final String text => text,
  _ => throw FormatException('Expected text: $value'),
};

DateTime _time(Object? value) => DateTime.parse(_string(value)).toUtc();
