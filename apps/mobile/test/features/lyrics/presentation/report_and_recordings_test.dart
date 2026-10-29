import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/lyrics/presentation/report_lyrics_sheet.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

const _longArtist =
    'Addis Ababa Holy Trinity Cathedral Choir with the Sunday School';

/// Three songs: "two-takes" with a synced recording (used for lyrics) and a
/// text-only one, "no-takes" with none, and "long" with a long artist name.
class _Lyrics implements LyricsRepository {
  static Song _song(String id) => Song(
    id: id,
    title: id,
    sections: const [
      LyricSection(
        id: 'v1',
        kind: SectionKind.verse,
        lines: [LyricLine('Amen')],
      ),
    ],
  );

  static const _recordings = [
    Recording(
      id: 'two-takes-a',
      songId: 'two-takes',
      source: RecordingSource.youtube,
      artist: 'Choir A',
      duration: Duration(minutes: 3, seconds: 5),
    ),
    Recording(
      id: 'two-takes-b',
      songId: 'two-takes',
      source: RecordingSource.localFile,
    ),
    Recording(
      id: 'long-a',
      songId: 'long',
      source: RecordingSource.telegram,
      artist: _longArtist,
      duration: Duration(minutes: 12, seconds: 41),
    ),
  ];

  @override
  Future<List<Song>> songs() async => [
    for (final id in ['two-takes', 'no-takes', 'long']) _song(id),
  ];
  @override
  Future<Song?> song(String id) async =>
      (await songs()).where((s) => s.id == id).firstOrNull;
  @override
  Future<List<Recording>> recordings(String songId) async => [
    for (final r in _recordings)
      if (r.songId == songId) r,
  ];
  @override
  Future<SyncTiming?> timing(String recordingId) async =>
      recordingId == 'two-takes-b'
      ? null
      : SyncTiming(recordingId: recordingId, starts: const [Duration.zero]);
  @override
  Future<List<Song>> search(String query) async => const [];
}

class _App {
  _App(this.db, this.catalog);

  final ZemaDatabase db;
  final FakeCatalogRepository catalog;

  Future<List<String>> queued() async => [
    for (final q in await db.reportsDao.all()) q.report.songId,
  ];
}

/// Lets database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Opens the Recordings tab. Its spinner animates while the recordings load
/// from the database, so frames are pumped until they are in.
Future<void> _openRecordings(WidgetTester tester) async {
  await tester.tap(find.text(_l10n.songDetailRecordingsTab));
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Song detail of [songId], with the index saved.
Future<_App> _pump(
  WidgetTester tester, {
  String songId = 'two-takes',
  double textScale = 1,
  Brightness phoneBrightness = Brightness.dark,
  bool backendConfigured = true,
}) async {
  useScreen(tester, size: const Size(400, 860), textScale: textScale);
  final catalog = FakeCatalogRepository(lyrics: _Lyrics());
  final db = memoryDatabase();
  await pumpZemaApp(
    tester,
    database: db,
    catalog: catalog,
    phoneBrightness: phoneBrightness,
    backendConfigured: backendConfigured,
  );
  await _settle(tester);
  GoRouter.of(tester.element(find.byType(Scaffold).first))
      .go(AppRoutes.song(songId));
  await _settle(tester);
  return _App(db, catalog);
}

Future<void> _openReport(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_l10n.songDetailMoreOptions));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l10n.reportLyrics));
  await tester.pumpAndSettle();
}

/// Send (its label turns into a spinner while sending).
Finder get _send => find.descendant(
  of: find.byType(ReportLyricsSheet),
  matching: find.byType(FilledButton),
);

bool _sendEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_send).onPressed != null;

Future<void> _sendReport(WidgetTester tester, {String? note}) async {
  await tester.tap(find.text(_l10n.reportReasonWrongWords));
  await tester.pump();
  if (note != null) await tester.enterText(find.byType(TextField), note);
  await tester.tap(_send);
  await _settle(tester);
}

Finder _tile(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));

Finder _inTile(String title, String text) =>
    find.descendant(of: _tile(title), matching: find.text(text));

void main() {
  group('Report wrong lyrics from Song detail', () {
    testWidgets('the sheet asks for a reason; Send is off until one is '
        'picked', (tester) async {
      await _pump(tester);
      await _openReport(tester);

      expect(find.byType(ReportLyricsSheet), findsOneWidget);
      for (final reason in [
        _l10n.reportReasonWrongWords,
        _l10n.reportReasonWrongTiming,
        _l10n.reportReasonWrongSong,
        _l10n.reportReasonOther,
      ]) {
        expect(find.text(reason), findsOneWidget);
      }
      expect(find.text(_l10n.reportNote), findsOneWidget);
      expect(_sendEnabled(tester), isFalse);

      await tester.tap(find.text(_l10n.reportReasonWrongSong));
      await tester.pump();
      expect(_sendEnabled(tester), isTrue);
    });

    testWidgets('online: sent with the trimmed note, and thanks', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _openReport(tester);
      await _sendReport(tester, note: '  Line 2 is wrong  ');

      expect(find.byType(ReportLyricsSheet), findsNothing);
      expect(find.text(_l10n.reportSent), findsOneWidget);
      final sent = app.catalog.reports.single;
      expect(sent.songId, 'two-takes');
      expect(sent.reason, ReportReason.wrongWords);
      expect(sent.note, 'Line 2 is wrong');
      expect(sent.recordingId, isNull);
    });

    testWidgets('a blank note is sent as none', (tester) async {
      final app = await _pump(tester);
      await _openReport(tester);
      await _sendReport(tester, note: '   ');

      expect(app.catalog.reports.single.note, isNull);
    });

    testWidgets('offline: kept on the phone to send later', (tester) async {
      final app = await _pump(tester);
      app.catalog.failure = const NetworkFailure('offline');
      await _openReport(tester);
      await _sendReport(tester);

      expect(find.text(_l10n.reportQueued), findsOneWidget);
      expect(await tester.runAsync(app.queued), ['two-takes']);
    });

    testWidgets('past the daily limit: a friendly message, nothing kept', (
      tester,
    ) async {
      final app = await _pump(tester);
      app.catalog.failure = const RateLimitFailure('PT429');
      await _openReport(tester);
      await _sendReport(tester);

      expect(find.text(_l10n.reportLimited), findsOneWidget);
      expect(await tester.runAsync(app.queued), isEmpty);
    });

    testWidgets('refused: says it could not send', (tester) async {
      final app = await _pump(tester);
      app.catalog.failure = const BackendFailure('22023');
      await _openReport(tester);
      await _sendReport(tester);

      expect(find.text(_l10n.reportFailed), findsOneWidget);
    });

    testWidgets('while sending: a spinner, and the sheet is locked', (
      tester,
    ) async {
      final app = await _pump(tester);
      final gate = app.catalog.reportGate = Completer<void>();
      await _openReport(tester);
      await tester.tap(find.text(_l10n.reportReasonWrongWords));
      await tester.pump();
      await tester.tap(_send);
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(ReportLyricsSheet),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(_sendEnabled(tester), isFalse);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, _l10n.actionCancel),
            )
            .onPressed,
        isNull,
      );

      gate.complete();
      await _settle(tester);
      expect(find.text(_l10n.reportSent), findsOneWidget);
    });

    testWidgets('Cancel closes without sending', (tester) async {
      final app = await _pump(tester);
      await _openReport(tester);
      await tester.tap(find.text(_l10n.reportReasonOther));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, _l10n.actionCancel));
      await _settle(tester);

      expect(find.byType(ReportLyricsSheet), findsNothing);
      expect(app.catalog.reportCalls, 0);
    });

    testWidgets('the note stops at 500 characters', (tester) async {
      await _pump(tester);
      await _openReport(tester);
      await tester.enterText(find.byType(TextField), 'x' * 600);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.text,
        hasLength(ReportLyricsSheet.maxNoteLength),
      );
      expect(find.text('500/500'), findsOneWidget);
    });

    testWidgets('a build with no backend has no menu', (tester) async {
      await _pump(tester, backendConfigured: false);

      expect(find.byTooltip(_l10n.songDetailMoreOptions), findsNothing);
    });
  });

  group('Recordings tab', () {
    testWidgets('each recording with artist, source, duration and Synced or '
        'Text only; the first is marked used', (tester) async {
      await _pump(tester);
      await _openRecordings(tester);

      expect(_inTile('Choir A', 'YouTube · 3:05'), findsOneWidget);
      expect(_inTile('Choir A', _l10n.songRecordingSynced), findsOneWidget);
      expect(_inTile('Choir A', _l10n.songRecordingUsed), findsOneWidget);

      final other = _l10n.unknownArtist;
      expect(_inTile(other, _l10n.songSourceLocal), findsOneWidget);
      expect(_inTile(other, _l10n.songRecordingTextOnly), findsOneWidget);
      expect(_inTile(other, _l10n.songRecordingUsed), findsNothing);
      expect(find.text(_l10n.songRecordingUsed), findsOneWidget);

      // Listed in the order the lyrics view picks from.
      expect(
        tester.getTopLeft(_tile('Choir A')).dy,
        lessThan(tester.getTopLeft(_tile(other)).dy),
      );
    });

    testWidgets('no recordings: an empty state', (tester) async {
      await _pump(tester, songId: 'no-takes');
      await _openRecordings(tester);

      expect(find.text(_l10n.songRecordingsEmpty), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('fits at 1.3× text in ${brightness.name} mode', (
        tester,
      ) async {
        await _pump(
          tester,
          songId: 'long',
          textScale: 1.3,
          phoneBrightness: brightness,
        );
        await _openRecordings(tester);

        expect(find.text(_longArtist), findsOneWidget);
        expect(find.text('Telegram · 12:41'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
