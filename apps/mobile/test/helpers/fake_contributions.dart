import 'package:zema_core/zema_core.dart';

import 'fake_auth.dart';

/// Contributions in memory, with the backend's rules: the shared checks,
/// the limits (20 open, 30 a day), resubmitting only "changes requested",
/// and reviews only by a moderator, never of their own, once.
///
/// Calls act as [userId]; switch it to act as someone else.
class FakeContributionRepository implements ContributionRepository {
  FakeContributionRepository({String? userId, this.moderator = false})
    : userId = userId ?? testUser.id;

  /// Who calls ([testUser] unless given); set it to null for no signed-in
  /// user.
  String? userId;

  /// Whether [userId] is a moderator.
  bool moderator;

  /// The catalog songs, for the checks on recordings and syncs, and the
  /// queue's current song.
  final songs = <String, SongDocument>{};

  /// Authors' names in the queue, by user id.
  final names = <String, String>{testUser.id: testUser.name ?? 'Test'};

  /// Thrown by the next call when set (then cleared).
  ZemaFailure? failure;

  /// The server's clock: each change is a second after the last.
  DateTime clock = DateTime.utc(2026, 11, 2, 9);

  final _rows = <_Row>[];
  var _next = 0;

  /// Every contribution, oldest first.
  List<SubmittedContribution> get all => [for (final r in _rows) r.value];

  /// Every submit and resubmit, in order.
  final sent = <Contribution>[];

  DateTime _tick() => clock = clock.add(const Duration(seconds: 1));

  String _caller() {
    final f = failure;
    failure = null;
    if (f != null) throw f;
    return userId ?? (throw const AuthFailure('not signed in'));
  }

  Never _refuse(ContributionError error) =>
      throw ContributionFailure(error.code, code: error.code);

  void _check(Contribution c) {
    final current = c.songId == null ? null : songs[c.songId];
    if (c.kind != ContributionKind.newSong && current == null) {
      _refuse(ContributionError.unknownSong);
    }
    final errors = contributionErrors(
      c,
      currentSong: current?.song,
      existingRecording: current?.recordings
          .where((r) => r.id == c.timing?.recordingId)
          .firstOrNull,
    );
    if (errors.isNotEmpty) _refuse(errors.first);
    if (c.kind == ContributionKind.syncTiming &&
        !current!.recordings.any((r) => r.id == c.timing!.recordingId)) {
      _refuse(ContributionError.unknownRecording);
    }
  }

  @override
  Future<String> submit(Contribution contribution) async {
    final author = _caller();
    _check(contribution);
    final mine = _rows.where((r) => r.author == author);
    if (mine
            .where(
              (r) =>
                  r.value.status == ContributionStatus.pending ||
                  r.value.status == ContributionStatus.changesRequested,
            )
            .length >=
        20) {
      _refuse(ContributionError.tooManyOpen);
    }
    final now = _tick();
    if (mine
            .where(
              (r) =>
                  now.difference(r.value.createdAt) < const Duration(days: 1),
            )
            .length >=
        30) {
      _refuse(ContributionError.tooManyToday);
    }
    sent.add(contribution);
    final id = 'contribution-${++_next}';
    _rows.add(
      _Row(
        author,
        SubmittedContribution(
          id: id,
          contribution: contribution,
          status: ContributionStatus.pending,
          songId: contribution.songId,
          createdAt: now,
          submittedAt: now,
        ),
      ),
    );
    return id;
  }

  @override
  Future<int> resubmit(String id, Contribution contribution) async {
    final author = _caller();
    final row = _rows.where((r) => r.value.id == id).firstOrNull;
    if (row == null ||
        row.author != author ||
        row.value.status != ContributionStatus.changesRequested) {
      _refuse(ContributionError.notEditable);
    }
    _check(contribution);
    sent.add(contribution);
    final old = row.value;
    row.value = SubmittedContribution(
      id: id,
      contribution: contribution,
      status: ContributionStatus.pending,
      songId: old.songId,
      revision: old.revision + 1,
      reviewNote: old.reviewNote,
      createdAt: old.createdAt,
      submittedAt: _tick(),
      reviewedAt: old.reviewedAt,
    );
    return old.revision + 1;
  }

  @override
  Future<List<SubmittedContribution>> mine() async {
    final author = _caller();
    return [
      for (final r in _rows.reversed)
        if (r.author == author) r.value,
    ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  @override
  Future<List<QueuedContribution>> queue({ContributionKind? kind}) async {
    final caller = _caller();
    if (!moderator) _refuse(ContributionError.notModerator);
    return [
      for (final r in _rows)
        if (r.value.status == ContributionStatus.pending &&
            r.author != caller &&
            (kind == null || r.value.kind == kind))
          QueuedContribution(
            id: r.value.id,
            contribution: r.value.contribution,
            submittedAt: r.value.submittedAt,
            revision: r.value.revision,
            authorName: names[r.author],
            previousNote: r.value.reviewNote,
            currentVersion: r.value.songId == null ? null : 1,
            currentSong: songs[r.value.songId],
          ),
    ]..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  @override
  Future<String?> review(
    String id,
    ReviewDecision decision, {
    String? note,
  }) async {
    final caller = _caller();
    if (!moderator) _refuse(ContributionError.notModerator);
    final clean = note?.trim() ?? '';
    if (clean.length > maxNoteLength) _refuse(ContributionError.noteTooLong);
    if (decision.needsNote && clean.isEmpty) {
      _refuse(ContributionError.noteRequired);
    }
    final row = _rows.where((r) => r.value.id == id).firstOrNull;
    if (row == null) _refuse(ContributionError.unknownContribution);
    if (row.author == caller) _refuse(ContributionError.ownContribution);
    final old = row.value;
    if (old.status != ContributionStatus.pending) {
      _refuse(ContributionError.alreadyReviewed);
    }
    final songId = decision == ReviewDecision.approve
        ? old.songId ?? old.contribution.song?.id
        : old.songId;
    row.value = SubmittedContribution(
      id: id,
      contribution: old.contribution,
      status: ContributionStatus.fromWire(decision.wire),
      songId: songId,
      revision: old.revision,
      reviewNote: clean.isEmpty ? null : clean,
      createdAt: old.createdAt,
      submittedAt: old.submittedAt,
      reviewedAt: _tick(),
    );
    return songId;
  }

  /// Fingerprints attached, by contribution id.
  final attached = <String, AudioFingerprint>{};

  /// Library fingerprints waiting for a moderator.
  final pending = <PendingFingerprint>[];

  /// Fingerprint reviews made: id, and whether approved.
  final fingerprintReviews = <(String, bool)>[];

  @override
  Future<void> attachFingerprint(
    String id,
    AudioFingerprint fingerprint,
  ) async {
    final user = _caller();
    final row = _rows.where((r) => r.value.id == id).firstOrNull;
    if (row == null || row.author != user) {
      _refuse(ContributionError.notEditable);
    }
    attached[id] = fingerprint;
  }

  @override
  Future<List<PendingFingerprint>> pendingFingerprints() async {
    _caller();
    if (!moderator) throw const AuthFailure('not a moderator');
    return [...pending];
  }

  @override
  Future<void> reviewFingerprint(String id, {required bool approve}) async {
    _caller();
    if (!moderator) throw const AuthFailure('not a moderator');
    fingerprintReviews.add((id, approve));
    pending.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<PendingTrackPrint>> pendingTrackPrints() async {
    _caller();
    if (!moderator) throw const AuthFailure('not a moderator');
    return const [];
  }

  @override
  Future<void> reviewTrackPrint(int id, {required bool approve}) async {
    _caller();
    if (!moderator) throw const AuthFailure('not a moderator');
  }
}

class _Row {
  _Row(this.author, this.value);

  final String author;
  SubmittedContribution value;
}
