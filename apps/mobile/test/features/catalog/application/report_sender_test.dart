import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/reports_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/catalog/application/report_sender.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';

CatalogEntry _entry(String id) =>
    catalogEntry(Song(id: id, title: id, sections: const []));

LyricsReport _report(String songId, {String? note}) =>
    LyricsReport(songId: songId, reason: ReportReason.wrongWords, note: note);

void main() {
  late ZemaDatabase db;
  late FakeCatalogRepository catalog;
  late SharedPreferences preferences;
  late ReportSender sender;

  Future<List<String>> queued() async => [
    for (final q in await db.reportsDao.all()) q.report.songId,
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    await db.catalogDao.replaceAll([
      for (final id in ['a', 'b', 'c']) _entry(id),
    ]);
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    catalog = FakeCatalogRepository();
    sender = ReportSender(
      catalog: catalog,
      reports: db.reportsDao,
      index: db.catalogDao,
      preferences: preferences,
    );
  });
  tearDown(() => db.close());

  group('installId', () {
    test('is made once, kept, and fits the server (8–64 characters)', () {
      final id = installId(preferences);
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(installId(preferences), id);
      expect(preferences.getString('catalog.installId'), id);
    });

    test('differs between installs', () async {
      final first = installId(preferences);
      SharedPreferences.setMockInitialValues({});
      final other = await SharedPreferences.getInstance();
      expect(installId(other), isNot(first));
    });
  });

  group('send', () {
    test(
      'online: sent with the reason, note, recording and install ID',
      () async {
        final outcome = await sender.send(
          const LyricsReport(
            songId: 'a',
            reason: ReportReason.wrongTiming,
            recordingId: 'a-rec',
            note: 'Late',
          ),
        );

        expect(outcome, ReportOutcome.sent);
        final sent = catalog.reports.single;
        expect(sent.songId, 'a');
        expect(sent.reason, ReportReason.wrongTiming);
        expect(sent.recordingId, 'a-rec');
        expect(sent.note, 'Late');
        expect(sent.installId, installId(preferences));
        expect(await queued(), isEmpty);
      },
    );

    test('offline: queued on the phone', () async {
      catalog.failure = const NetworkFailure('offline');

      expect(await sender.send(_report('a', note: 'n')), ReportOutcome.queued);

      final saved = (await db.reportsDao.all()).single.report;
      expect(saved.songId, 'a');
      expect(saved.note, 'n');
    });

    test('past the daily limit: limited, and not queued', () async {
      catalog.failure = const RateLimitFailure('PT429');

      expect(await sender.send(_report('a')), ReportOutcome.limited);
      expect(await queued(), isEmpty);
    });

    test('refused: failed, and not queued', () async {
      catalog.failure = const BackendFailure('22023 Unknown song');

      expect(await sender.send(_report('a')), ReportOutcome.failed);
      expect(await queued(), isEmpty);
    });

    test('no backend: failed, nothing queued', () async {
      sender = ReportSender(
        catalog: null,
        reports: db.reportsDao,
        index: db.catalogDao,
        preferences: preferences,
      );

      expect(await sender.send(_report('a')), ReportOutcome.failed);
      expect(await queued(), isEmpty);
    });

    test('sends the queue first, then the new report', () async {
      await db.reportsDao.add(_report('a'));
      await db.reportsDao.add(_report('b'));

      await sender.send(_report('c'));

      expect([for (final r in catalog.reports) r.songId], ['a', 'b', 'c']);
      expect(await queued(), isEmpty);
    });

    test('offline again: the new report joins the end of the queue', () async {
      await db.reportsDao.add(_report('a'));
      catalog.failure = const NetworkFailure('offline');

      await sender.send(_report('b'));

      expect(await queued(), ['a', 'b']);
    });
  });

  group('flush', () {
    test('sends oldest first and empties the queue', () async {
      for (final id in ['c', 'a', 'b']) {
        await db.reportsDao.add(_report(id));
      }

      await sender.flush();

      expect([for (final r in catalog.reports) r.songId], ['c', 'a', 'b']);
      expect(await queued(), isEmpty);
    });

    test('a report for a song no longer in the index is dropped quietly, '
        'without a call', () async {
      await db.reportsDao.add(_report('gone'));
      await db.reportsDao.add(_report('a'));

      await sender.flush();

      expect(catalog.reportCalls, 1);
      expect([for (final r in catalog.reports) r.songId], ['a']);
      expect(await queued(), isEmpty);
    });

    test('a report refused for good is dropped; the rest are sent', () async {
      catalog.reportFailures['a'] = const BackendFailure('22023');
      await db.reportsDao.add(_report('a'));
      await db.reportsDao.add(_report('b'));

      await sender.flush();

      expect([for (final r in catalog.reports) r.songId], ['b']);
      expect(await queued(), isEmpty);
    });

    test('offline: stops at the first and keeps them all', () async {
      catalog.failure = const NetworkFailure('offline');
      await db.reportsDao.add(_report('a'));
      await db.reportsDao.add(_report('b'));

      await sender.flush();

      expect(catalog.reportCalls, 1);
      expect(await queued(), ['a', 'b']);
    });

    test('past the limit: keeps the one refused and the rest', () async {
      catalog.reportFailures['b'] = const RateLimitFailure('PT429');
      for (final id in ['a', 'b', 'c']) {
        await db.reportsDao.add(_report(id));
      }

      await sender.flush();

      expect([for (final r in catalog.reports) r.songId], ['a']);
      expect(catalog.reportCalls, 2);
      expect(await queued(), ['b', 'c']);
    });

    test('a second flush while one runs shares it', () async {
      await db.reportsDao.add(_report('a'));
      final gate = catalog.reportGate = Completer<void>();

      final first = sender.flush();
      final second = sender.flush();
      await pumpEventQueue();
      gate.complete();
      await Future.wait([first, second]);

      expect(catalog.reportCalls, 1);
      expect(await queued(), isEmpty);
    });
  });

  group('canReportProvider', () {
    Future<bool> canReport(String songId, {required bool backend}) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(preferences),
          catalogRepositoryProvider.overrideWithValue(backend ? catalog : null),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(canReportProvider(songId), (_, _) {});
      await pumpEventQueue();
      return listener.read();
    }

    test('a song in the index can be reported', () async {
      expect(await canReport('a', backend: true), isTrue);
    });

    test('a song not in the index cannot', () async {
      expect(await canReport('bundled-only', backend: true), isFalse);
    });

    test('nothing can be reported in a build with no backend', () async {
      expect(await canReport('a', backend: false), isFalse);
    });
  });
}
