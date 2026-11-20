import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

import 'supabase_auth_repository.dart';

/// Contributions through the backend's functions: `submit_contribution`,
/// `resubmit_contribution`, `moderator_queue`, `review_contribution`,
/// `attach_fingerprint`, `moderator_fingerprints` and `review_fingerprint`.
/// Users read their own rows of `contributions` directly.
class SupabaseContributionRepository implements ContributionRepository {
  SupabaseContributionRepository(this._auth);

  final SupabaseAuthRepository _auth;

  @override
  Future<String> submit(Contribution contribution) => _run(
    'submit_contribution',
    (client, _) async => _string(
      await client.rpc<Object?>(
        'submit_contribution',
        params: {
          'kind': contribution.kind.wire,
          'payload': contribution.toPayload(),
          'song_id': contribution.songId,
          'base_version': contribution.baseVersion,
        },
      ),
    ),
  );

  @override
  Future<int> resubmit(String id, Contribution contribution) => _run(
    'resubmit_contribution',
    (client, _) async => switch (await client.rpc<Object?>(
      'resubmit_contribution',
      params: {'id': id, 'payload': contribution.toPayload()},
    )) {
      final int revision => revision,
      final other => throw FormatException('Expected a revision: $other'),
    },
  );

  @override
  Future<List<SubmittedContribution>> mine() =>
      _run('my contributions', (client, userId) async {
        final rows = await client
            .from('contributions')
            .select(
              'id, kind, status, song_id, base_version, payload, revision, '
              'review_note, created_at, submitted_at, reviewed_at',
            )
            .eq('author_id', userId)
            .order('submitted_at', ascending: false);
        return [for (final row in rows) _submitted(row)];
      });

  @override
  Future<List<QueuedContribution>> queue({ContributionKind? kind}) =>
      _run('moderator_queue', (client, _) async {
        final rows = await client.rpc<List<dynamic>>(
          'moderator_queue',
          params: {'only_kind': kind?.wire},
        );
        return [
          for (final row in rows.cast<Map<String, dynamic>>()) _queued(row),
        ];
      });

  @override
  Future<String?> review(String id, ReviewDecision decision, {String? note}) =>
      _run(
        'review_contribution',
        (client, _) async => switch (await client.rpc<Object?>(
          'review_contribution',
          params: {'id': id, 'decision': decision.wire, 'note': note},
        )) {
          null => null,
          final String songId => songId,
          final other => throw FormatException('Expected a song id: $other'),
        },
      );

  @override
  Future<void> attachFingerprint(String id, AudioFingerprint fingerprint) =>
      _run(
        'attach_fingerprint',
        (client, _) => client.rpc<void>(
          'attach_fingerprint',
          params: {
            'contribution': id,
            'version': fingerprintVersion,
            'frame_count': fingerprint.frameCount,
            'hashes': fingerprint.hashes,
            'frames': fingerprint.frames,
          },
        ),
      );

  @override
  Future<List<PendingFingerprint>> pendingFingerprints() =>
      _run('moderator_fingerprints', (client, _) async {
        final rows = await client.rpc<List<dynamic>>('moderator_fingerprints');
        return [
          for (final row in rows.cast<Map<String, dynamic>>())
            PendingFingerprint(
              id: _string(row['id']),
              recordingId: _string(row['recording_id']),
              songId: _string(row['song_id']),
              songTitle: _string(row['song_title']),
              recordingArtist: row['recording_artist'] as String?,
              recordingDuration: switch (row['duration_ms']) {
                final int ms => Duration(milliseconds: ms),
                _ => null,
              },
              frameCount: row['frame_count']! as int,
              hashCount: row['hash_count']! as int,
              installs: row['installs']! as int,
              sentAt: _time(row['created_at']),
            ),
        ];
      });

  @override
  Future<void> reviewFingerprint(String id, {required bool approve}) => _run(
    'review_fingerprint',
    (client, _) => client.rpc<void>(
      'review_fingerprint',
      params: {'id': id, 'approve': approve},
    ),
  );

  @override
  Future<List<PendingTrackPrint>> pendingTrackPrints() =>
      _run('moderator_track_prints', (client, _) async {
        final rows = await client.rpc<List<dynamic>>('moderator_track_prints');
        return [
          for (final row in rows.cast<Map<String, dynamic>>())
            PendingTrackPrint(
              id: row['id']! as int,
              songId: _string(row['song_id']),
              songTitle: _string(row['song_title']),
              songArtist: row['song_artist'] as String?,
              duration: Duration(milliseconds: row['duration_ms']! as int),
              installs: row['installs']! as int,
              conflictSongId: row['conflict_song_id'] as String?,
              conflictSongTitle: row['conflict_song_title'] as String?,
              sentAt: _time(row['created_at']),
            ),
        ];
      });

  @override
  Future<void> reviewTrackPrint(int id, {required bool approve}) => _run(
    'review_track_print',
    (client, _) => client.rpc<void>(
      'review_track_print',
      params: {'id': id, 'approve': approve},
    ),
  );

  /// Runs [call] as the signed-in user; a refusal the backend names becomes
  /// a [ContributionFailure] with its code.
  Future<T> _run<T>(
    String function,
    Future<T> Function(SupabaseClient client, String userId) call,
  ) => _auth.run(function, (client, userId) async {
    try {
      return await call(client, userId);
    } on PostgrestException catch (e) {
      final code = e.message;
      if (code == ContributionError.notSignedIn.code) {
        throw AuthFailure('$function: not signed in', cause: e);
      }
      if (ContributionError.fromCode(code) != null) {
        throw ContributionFailure('$function: $code', code: code, cause: e);
      }
      rethrow;
    }
  });
}

SubmittedContribution _submitted(Map<String, dynamic> row) {
  final kind = ContributionKind.fromWire(_string(row['kind']));
  final songId = row['song_id'] as String?;
  final baseVersion = row['base_version'] as int?;
  return SubmittedContribution(
    id: _string(row['id']),
    contribution: Contribution.fromPayload(
      kind,
      row['payload'],
      // A new song keeps its proposed id; songId is the song it became.
      songId: kind == ContributionKind.newSong ? null : songId,
      baseVersion: baseVersion,
    ),
    status: ContributionStatus.fromWire(_string(row['status'])),
    songId: songId,
    revision: row['revision'] as int? ?? 1,
    reviewNote: row['review_note'] as String?,
    createdAt: _time(row['created_at']),
    submittedAt: _time(row['submitted_at']),
    reviewedAt: row['reviewed_at'] == null ? null : _time(row['reviewed_at']),
  );
}

QueuedContribution _queued(Map<String, dynamic> row) {
  final kind = ContributionKind.fromWire(_string(row['kind']));
  final document = row['current_document'];
  return QueuedContribution(
    id: _string(row['id']),
    contribution: Contribution.fromPayload(
      kind,
      row['payload'],
      songId: row['song_id'] as String?,
      baseVersion: row['base_version'] as int?,
    ),
    submittedAt: _time(row['submitted_at']),
    revision: row['revision'] as int? ?? 1,
    authorName: row['author_name'] as String?,
    previousNote: row['review_note'] as String?,
    currentVersion: row['current_version'] as int?,
    currentSong: document == null ? null : SongDocument.fromJson(document),
  );
}

String _string(Object? value) => switch (value) {
  final String text => text,
  _ => throw FormatException('Expected text: $value'),
};

DateTime _time(Object? value) => DateTime.parse(_string(value)).toUtc();
