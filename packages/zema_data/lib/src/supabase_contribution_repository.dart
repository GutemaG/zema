import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

import 'supabase_auth_repository.dart';

/// Contributions through the backend's functions: `submit_contribution`,
/// `resubmit_contribution`, `moderator_queue` and `review_contribution`.
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
