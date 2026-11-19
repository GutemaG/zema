import '../catalog/catalog.dart';

/// Where a listener's report is. [wire] is the backend's name.
enum ReportStatus {
  open('open'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.wire);

  final String wire;

  static ReportStatus? fromWire(String wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

/// The backend's name of each [ReportReason].
const reportReasonWire = {
  ReportReason.wrongWords: 'wrong_words',
  ReportReason.wrongTiming: 'wrong_timing',
  ReportReason.wrongSong: 'wrong_song',
  ReportReason.other: 'other',
};

/// A listener's report, as moderators see it (never who sent it).
class ModeratorReport {
  const ModeratorReport({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.songId,
    this.songTitle,
    this.recordingId,
    this.note,
  });

  final String id;

  /// Null when the song has been deleted since.
  final String? songId;
  final String? songTitle;
  final String? recordingId;
  final ReportReason reason;
  final String? note;
  final ReportStatus status;
  final DateTime createdAt;
}

/// A catalog song as moderators list it: approved, or hidden from listeners.
class ModeratedSong {
  const ModeratedSong({
    required this.id,
    required this.title,
    required this.hidden,
    required this.version,
    required this.lineCount,
    required this.updatedAt,
    this.artist,
  });

  final String id;
  final String title;
  final String? artist;
  final bool hidden;
  final int version;
  final int lineCount;
  final DateTime updatedAt;
}

/// The moderator's work beyond contributions. Moderators only; the backend
/// refuses anyone else. Throws [ZemaFailure]s only.
abstract interface class ModerationRepository {
  /// Reports with [status] (every status when null), newest first.
  Future<List<ModeratorReport>> reports(
    ReportStatus? status, {
    int limit = 100,
    int offset = 0,
  });

  /// Marks report [id] resolved or dismissed.
  Future<void> resolveReport(String id, ReportStatus status);

  /// Approved and hidden songs whose title, artist or id contain [query],
  /// by title.
  Future<List<ModeratedSong>> songs({
    String query = '',
    int limit = 50,
    int offset = 0,
  });

  /// Approved or hidden song [id] with its recordings and timings, or null.
  Future<SongDocument?> song(String id);

  /// Hides song [id] from listeners, or shows it again.
  Future<void> setHidden(String id, {required bool hidden});
}
