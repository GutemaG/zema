import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/reports_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  late ZemaDatabase db;

  setUp(() => db = ZemaDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('keeps reports oldest first, with every field', () async {
    final dao = db.reportsDao;
    await dao.add(
      const LyricsReport(
        songId: 'a',
        reason: ReportReason.wrongTiming,
        recordingId: 'a-rec',
        note: 'Late by a line',
      ),
    );
    await dao.add(const LyricsReport(songId: 'b', reason: ReportReason.other));

    final queued = await dao.all();
    expect([for (final q in queued) q.report.songId], ['a', 'b']);
    final first = queued.first.report;
    expect(first.reason, ReportReason.wrongTiming);
    expect(first.recordingId, 'a-rec');
    expect(first.note, 'Late by a line');
    expect(queued.last.report.recordingId, isNull);
    expect(queued.last.report.note, isNull);
  });

  test('remove takes out one report', () async {
    final dao = db.reportsDao;
    for (final id in ['a', 'b', 'c']) {
      await dao.add(LyricsReport(songId: id, reason: ReportReason.wrongWords));
    }
    final queued = await dao.all();

    await dao.remove(queued[1].id);

    expect([for (final q in await dao.all()) q.report.songId], ['a', 'c']);
  });

  test('a reason this version does not know reads as Other', () async {
    await db
        .into(db.queuedReports)
        .insert(
          QueuedReportsCompanion.insert(
            songId: 'a',
            reason: 'from_the_future',
            createdAt: DateTime.utc(2026, 10, 29),
          ),
        );

    expect(
      (await db.reportsDao.all()).single.report.reason,
      ReportReason.other,
    );
  });
}
