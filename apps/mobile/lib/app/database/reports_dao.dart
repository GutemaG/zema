import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'reports_dao.g.dart';

/// A report of wrong lyrics for song [songId].
class LyricsReport {
  const LyricsReport({
    required this.songId,
    required this.reason,
    this.recordingId,
    this.note,
  });

  final String songId;
  final String? recordingId;
  final ReportReason reason;
  final String? note;

  @override
  String toString() => 'LyricsReport($songId ${reason.name})';
}

/// A report waiting to be sent, by its queue [id], with the [reportId] it
/// was first sent with.
typedef QueuedReport = ({int id, String reportId, LyricsReport report});

/// Reports of wrong lyrics waiting to be sent.
@DriftAccessor(tables: [QueuedReports])
class ReportsDao extends DatabaseAccessor<ZemaDatabase> with _$ReportsDaoMixin {
  ReportsDao(super.attachedDatabase);

  /// Queues [report], sent before as [reportId], behind any waiting ones.
  Future<void> add(LyricsReport report, {required String reportId}) =>
      into(queuedReports).insert(
        QueuedReportsCompanion.insert(
          reportId: reportId,
          songId: report.songId,
          recordingId: Value(report.recordingId),
          reason: report.reason.name,
          note: Value(report.note),
          createdAt: clock.now().toUtc(),
        ),
      );

  /// Every waiting report, oldest first. A row with a reason this version
  /// doesn't know counts as Other.
  Future<List<QueuedReport>> all() async {
    final rows = await (select(
      queuedReports,
    )..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
    return [
      for (final row in rows)
        (
          id: row.id,
          reportId: row.reportId,
          report: LyricsReport(
            songId: row.songId,
            recordingId: row.recordingId,
            reason:
                ReportReason.values.asNameMap()[row.reason] ??
                ReportReason.other,
            note: row.note,
          ),
        ),
    ];
  }

  Future<void> remove(int id) =>
      (delete(queuedReports)..where((r) => r.id.equals(id))).go();
}
