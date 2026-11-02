import '../catalog/catalog.dart';
import '../failures.dart';
import '../lyrics/lyrics_models.dart';

/// What a contribution adds to the catalog. [wire] is the backend's name.
enum ContributionKind {
  newSong('new_song'),
  editLyrics('edit_lyrics'),
  recording('recording'),
  syncTiming('sync_timing');

  const ContributionKind(this.wire);

  final String wire;

  /// Throws [LyricsFormatFailure] for a name this app doesn't know.
  static ContributionKind fromWire(String wire) => values.firstWhere(
    (k) => k.wire == wire,
    orElse: () =>
        throw LyricsFormatFailure('Unknown contribution kind "$wire"'),
  );
}

/// Where a contribution is in review. [wire] is the backend's name.
enum ContributionStatus {
  pending('pending'),
  approved('approved'),
  changesRequested('changes_requested'),
  rejected('rejected');

  const ContributionStatus(this.wire);

  final String wire;

  /// Throws [LyricsFormatFailure] for a name this app doesn't know.
  static ContributionStatus fromWire(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () =>
        throw LyricsFormatFailure('Unknown contribution status "$wire"'),
  );
}

/// A moderator's decision. [wire] is the status it gives.
enum ReviewDecision {
  approve('approved'),
  requestChanges('changes_requested'),
  reject('rejected');

  const ReviewDecision(this.wire);

  final String wire;

  /// Whether the moderator must say why.
  bool get needsNote => this != approve;
}

/// What a user sends for review. Each kind carries part of a song document
/// (`{song, recordings, timings}`, as the catalog serves it):
///
/// - [Contribution.newSong]: the song (its id a proposed slug), and maybe one
///   recording with its timing
/// - [Contribution.editLyrics]: the corrected song, based on [baseVersion]
/// - [Contribution.recording]: a recording of song [songId], maybe with its
///   timing
/// - [Contribution.syncTiming]: a timing for an existing recording
class Contribution {
  const Contribution.newSong(Song this.song, {this.recording, this.timing})
    : kind = ContributionKind.newSong,
      songId = null,
      baseVersion = null;

  const Contribution.editLyrics({
    required String this.songId,
    required int this.baseVersion,
    required Song this.song,
  }) : kind = ContributionKind.editLyrics,
       recording = null,
       timing = null;

  const Contribution.recording({
    required String this.songId,
    required Recording this.recording,
    this.timing,
  }) : kind = ContributionKind.recording,
       song = null,
       baseVersion = null;

  const Contribution.syncTiming({
    required String this.songId,
    required SyncTiming this.timing,
  }) : kind = ContributionKind.syncTiming,
       song = null,
       recording = null,
       baseVersion = null;

  /// Reads [payload] as a [kind] contribution. Throws [LyricsFormatFailure]
  /// when it doesn't hold what the kind needs.
  factory Contribution.fromPayload(
    ContributionKind kind,
    Object? payload, {
    String? songId,
    int? baseVersion,
  }) {
    if (payload is! Map) {
      throw const LyricsFormatFailure('A contribution must be a JSON object');
    }
    Object? first(String key) => switch (payload[key]) {
      null || [] => null,
      [final value, ...] => value,
      _ => throw LyricsFormatFailure('"$key" must be a list'),
    };
    final song = payload['song'] == null
        ? null
        : Song.fromJson(payload['song']);
    final recording = switch (first('recordings')) {
      null => null,
      final json => Recording.fromJson(json),
    };
    final timing = switch (first('timings')) {
      null => null,
      final json => SyncTiming.fromJson(json),
    };
    T need<T>(T? value, String what) =>
        value ??
        (throw LyricsFormatFailure('A ${kind.wire} contribution needs $what'));
    return switch (kind) {
      ContributionKind.newSong => Contribution.newSong(
        need(song, 'a song'),
        recording: recording,
        timing: timing,
      ),
      ContributionKind.editLyrics => Contribution.editLyrics(
        songId: need(songId, 'a song id'),
        baseVersion: need(baseVersion, 'a base version'),
        song: need(song, 'a song'),
      ),
      ContributionKind.recording => Contribution.recording(
        songId: need(songId, 'a song id'),
        recording: need(recording, 'a recording'),
        timing: timing,
      ),
      ContributionKind.syncTiming => Contribution.syncTiming(
        songId: need(songId, 'a song id'),
        timing: need(timing, 'a timing'),
      ),
    };
  }

  final ContributionKind kind;

  /// The catalog song it changes; null for a new song.
  final String? songId;

  /// The song version a correction was based on.
  final int? baseVersion;
  final Song? song;
  final Recording? recording;
  final SyncTiming? timing;

  /// The JSON the backend stores, without the parts this kind doesn't have.
  Map<String, Object?> toPayload() => {
    if (song case final song?) 'song': song.toJson(),
    if (recording case final recording?) 'recordings': [recording.toJson()],
    if (timing case final timing?) 'timings': [timing.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is Contribution &&
      other.kind == kind &&
      other.songId == songId &&
      other.baseVersion == baseVersion &&
      other.song == song &&
      other.recording == recording &&
      other.timing == timing;

  @override
  int get hashCode =>
      Object.hash(kind, songId, baseVersion, song, recording, timing);

  @override
  String toString() => 'Contribution(${kind.wire}, ${songId ?? song?.id})';
}

/// A contribution the signed-in user sent, and where it is in review.
class SubmittedContribution {
  const SubmittedContribution({
    required this.id,
    required this.contribution,
    required this.status,
    required this.createdAt,
    required this.submittedAt,
    this.songId,
    this.revision = 1,
    this.reviewNote,
    this.reviewedAt,
  });

  final String id;
  final Contribution contribution;
  final ContributionStatus status;

  /// The catalog song: the one it changes, or for an approved new song the
  /// one it became.
  final String? songId;

  /// 1, then one more each time it is sent again after "changes requested".
  final int revision;

  /// The moderator's comment or reason, if any.
  final String? reviewNote;
  final DateTime createdAt;

  /// When it was last sent for review.
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  ContributionKind get kind => contribution.kind;

  @override
  String toString() => 'SubmittedContribution($id, ${status.wire})';
}

/// A pending contribution in the moderator's queue.
class QueuedContribution {
  const QueuedContribution({
    required this.id,
    required this.contribution,
    required this.submittedAt,
    this.revision = 1,
    this.authorName,
    this.previousNote,
    this.currentVersion,
    this.currentSong,
  });

  final String id;
  final Contribution contribution;
  final DateTime submittedAt;
  final int revision;
  final String? authorName;

  /// The comment from the last review, when it was sent back before.
  final String? previousNote;

  /// The song as it is now in the catalog (for a correction's diff, or the
  /// lyrics a timing belongs to); null for a new song.
  final int? currentVersion;
  final SongDocument? currentSong;

  ContributionKind get kind => contribution.kind;

  /// Whether a correction was based on an older version than the current.
  bool get basedOnOlderVersion =>
      contribution.baseVersion != null &&
      currentVersion != null &&
      contribution.baseVersion! < currentVersion!;

  @override
  String toString() => 'QueuedContribution($id, ${kind.wire})';
}
