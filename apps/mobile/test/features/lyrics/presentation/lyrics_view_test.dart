import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema/features/lyrics/application/lyrics_prefs.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/presentation/lyrics_view.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema/features/lyrics/presentation/match_lyrics_sheet.dart';
import 'package:zema/features/lyrics/presentation/report_lyrics_sheet.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/player/presentation/mini_player.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/bundled_lyrics_repository.dart';
import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_lyrics.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

// Galatoomi's sample lines (test/fixtures/lyrics/galatoomi.lrc).
const _first = 'Waaqayyo nu jaallatee'; // 2.5 s
const _second = 'Ifa isaa nuuf kenne'; // 6.5 s
const _chorus = 'Galatoomi, galatoomi'; // 10.5, 26.5, 34.5 s
const _chorus2 = 'Maqaan kee haa ulfaatu'; // 14.5, 30.5, 38.5 s
const _last = 'Abdiin keenya si qofa'; // 22.5 s

class _App {
  _App(this.handler, this.backend);

  final ZemaAudioHandler handler;
  final FakeAudioBackend backend;

  Future<void> at(WidgetTester tester, int ms) async {
    backend.advanceTo(Duration(milliseconds: ms));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Lets asset loading and database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// The app on Now Playing, playing the library's [titles] in order.
Future<_App> _pump(
  WidgetTester tester, {
  List<String> titles = const ['Galatoomi'],
  double textScale = 1,
  Brightness phoneBrightness = Brightness.dark,
  LyricsRepository? lyricsRepository,
  FakeCatalogRepository? catalog,
  ZemaFailure? failAfterStart,
  ZemaDatabase? database,
  bool lyricsMode = true,
  Size size = const Size(400, 860),
}) async {
  useScreen(tester, size: size, textScale: textScale);
  final backend = FakeAudioBackend();
  final handler = fakeAudioHandler(backend);
  final db = database ?? memoryDatabase();
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner([
      for (final (i, title) in titles.indexed)
        scannedAudio(i + 1, '/m/$i.mp3', title: title),
    ]),
    database: db,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    lyricsRepository: lyricsRepository,
    catalog: catalog,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  await _settle(tester);
  // The index is saved; downloading lyrics fails from here on.
  catalog?.failure = failAfterStart;
  final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
  final byTitle = {for (final t in tracks) t.title: t};
  await handler.playTracks([for (final t in titles) byTitle[t]!]);
  await handler.pause();
  await _settle(tester);
  await tester.tap(find.byType(MiniPlayer));
  await _settle(tester);
  if (lyricsMode) {
    await tester.tap(find.byTooltip(_l10n.playerShowLyrics));
    await _settle(tester);
  }
  return _App(handler, backend);
}

TextStyle _style(WidgetTester tester, String text, [int at = 0]) =>
    DefaultTextStyle.of(tester.element(find.text(text).at(at))).style;

ZemaColors _colors(WidgetTester tester) =>
    tester.element(find.byType(LyricsView)).zemaColors;

/// The line's top as a share of the lyrics view's height.
double _place(WidgetTester tester, String text, [int at = 0]) {
  final view = tester.getRect(find.byType(LyricsView));
  return (tester.getTopLeft(find.text(text).at(at)).dy - view.top) /
      view.height;
}

/// A song with lines but no timing.
class _PlainLyrics implements LyricsRepository {
  static const plain = Song(
    id: 'plain',
    title: 'Galatoomi',
    sections: [
      LyricSection(
        id: 'v1',
        kind: SectionKind.verse,
        lines: [LyricLine('Plain one'), LyricLine('Plain two')],
      ),
    ],
  );

  @override
  Future<List<Song>> songs() async => [plain];
  @override
  Future<Song?> song(String id) async => id == plain.id ? plain : null;
  @override
  Future<List<Recording>> recordings(String songId) async => const [];
  @override
  Future<SyncTiming?> timing(String recordingId) async => null;
  @override
  Future<List<Song>> search(String query) async => searchSongs([plain], query);
}

void main() {
  group('Under the artwork', () {
    testWidgets('the panel shows the line being sung and opens lyrics', (
      tester,
    ) async {
      final app = await _pump(tester, lyricsMode: false);
      expect(find.byType(LyricsPreview), findsOneWidget);
      expect(find.text(_first), findsOneWidget);

      await app.at(tester, 11000);
      expect(find.text(_chorus), findsOneWidget);

      await tester.tap(find.byType(LyricsPreview));
      await _settle(tester);
      expect(find.byType(LyricsView), findsOneWidget);
      expect(find.text(_last), findsOneWidget);
    });
  });

  group('Synced lyrics', () {
    testWidgets('highlight the current line, fade past ones, mark choruses', (
      tester,
    ) async {
      final app = await _pump(tester);
      await app.at(tester, 7000);
      final colors = _colors(tester);

      expect(_style(tester, _second).color, colors.primaryText);
      expect(_style(tester, _second).fontWeight, FontWeight.w700);
      expect(_style(tester, _first).color, colors.faint);
      expect(_style(tester, _chorus).color, colors.muted);
      expect(find.text(_l10n.lyricsChorus), findsNWidgets(3));
      expect(
        tester.getSemantics(find.text(_second)),
        isSemantics(isSelected: true),
      );

      // Each repeat is its own line.
      await app.at(tester, 27000);
      expect(_style(tester, _chorus, 1).color, colors.primaryText);
      expect(_style(tester, _chorus).color, colors.faint);
    });

    testWidgets('tapping a line seeks to it', (tester) async {
      final app = await _pump(tester);

      await tester.ensureVisible(find.text(_chorus2).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_chorus2).at(1));
      await tester.pump();
      expect(app.backend.position, const Duration(milliseconds: 30500));
    });

    testWidgets('the view follows the current line', (tester) async {
      final app = await _pump(tester);

      await app.at(tester, 39000);
      await tester.pumpAndSettle();
      expect(_place(tester, _chorus2, 2), closeTo(0.33, 0.05));

      await app.at(tester, 3000);
      await tester.pumpAndSettle();
      expect(_place(tester, _first), closeTo(0.33, 0.05));
    });

    testWidgets('a manual scroll pauses following for 3 s', (tester) async {
      final app = await _pump(tester);
      await app.at(tester, 3000);
      await tester.pumpAndSettle();

      await tester.drag(find.text(_first), const Offset(0, -300));
      await tester.pumpAndSettle();
      final scrolled = _place(tester, _first);
      expect(scrolled, lessThan(0));

      await app.at(tester, 7000);
      await tester.pump(const Duration(seconds: 2));
      expect(_place(tester, _first), scrolled);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(_place(tester, _second), closeTo(0.33, 0.05));
    });

    testWidgets('the sync offset moves the highlight at once', (tester) async {
      final app = await _pump(tester);
      await app.at(tester, 11000);
      expect(_style(tester, _chorus).color, _colors(tester).primaryText);

      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      await tester.tap(find.byTooltip(_l10n.lyricsOffsetLater));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_l10n.lyricsOffsetLater));
      await tester.pumpAndSettle();
      expect(find.text('+1.0 s'), findsOneWidget);
      expect(_style(tester, _second).color, _colors(tester).primaryText);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('lyricsOffset.galatoomi'), 1000);

      // Lines start 1 s later, so seeking to a line accounts for it.
      await tester.tap(find.text(_l10n.lyricsOffsetReset));
      await tester.pumpAndSettle();
      expect(find.text('0.0 s'), findsOneWidget);
      expect(_style(tester, _chorus).color, _colors(tester).primaryText);
      expect(app.handler.snapshot.playing, isFalse);
    });

    testWidgets('the default offset applies until a song has its own', (
      tester,
    ) async {
      final app = await _pump(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LyricsView)),
      );
      await container
          .read(lyricsDisplayProvider.notifier)
          .nudgeDefaultOffset(2);
      await app.at(tester, 11000);
      // Lines show 1 s later, so 11 s is still the second line.
      expect(_style(tester, _second).color, _colors(tester).primaryText);

      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      expect(find.text('+1.0 s'), findsOneWidget);
      await tester.tap(find.byTooltip(_l10n.lyricsOffsetEarlier));
      await tester.tap(find.byTooltip(_l10n.lyricsOffsetEarlier));
      await tester.pumpAndSettle();
      // Its own offset (0.0 s) now wins over the default.
      expect(find.text('0.0 s'), findsOneWidget);
      expect(_style(tester, _chorus).color, _colors(tester).primaryText);

      await tester.tap(find.text(_l10n.lyricsOffsetReset));
      await tester.pumpAndSettle();
      expect(find.text('+1.0 s'), findsOneWidget);
    });

    testWidgets('seeking includes the offset', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = await _pump(tester);
      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      await tester.tap(find.byTooltip(_l10n.lyricsOffsetLater));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_second));
      await tester.pump();
      expect(app.backend.position, const Duration(milliseconds: 7000));
    });

    testWidgets('A+ grows the text and keeps the current line in view', (
      tester,
    ) async {
      final app = await _pump(tester);
      await app.at(tester, 23000);
      await tester.pumpAndSettle();
      final before = _style(tester, _last).fontSize!;

      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip(_l10n.lyricsTextLarger));
        await tester.pumpAndSettle();
      }
      expect(find.text('140%'), findsOneWidget);
      expect(_style(tester, _last).fontSize, closeTo(before * 1.4, 0.01));
      expect(_place(tester, _last), closeTo(0.33, 0.05));
    });

    testWidgets('transliteration shows under each line when on', (
      tester,
    ) async {
      await _pump(tester, titles: const ['ብርሃን ሆንልን']);
      expect(find.text('Geta hoy birhan honlin'), findsNothing);

      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      await tester.tap(find.text(_l10n.lyricsShowTransliteration));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(find.text('ጌታ ሆይ ብርሃን ሆንልን'), findsOneWidget);
      expect(find.text('Geta hoy birhan honlin'), findsOneWidget);
    });

    testWidgets('the next track shows its own lyrics', (tester) async {
      final app = await _pump(tester, titles: const ['Galatoomi', 'ብርሃን ሆንልን']);
      expect(find.text(_first), findsOneWidget);

      await app.handler.skipToNext();
      await _settle(tester);
      expect(find.text(_first), findsNothing);
      expect(find.text('ጌታ ሆይ ብርሃን ሆንልን'), findsOneWidget);
    });
  });

  group('Other states', () {
    testWidgets('plain lyrics show without highlight or seeking', (
      tester,
    ) async {
      final app = await _pump(tester, lyricsRepository: _PlainLyrics());
      await app.at(tester, 5000);

      expect(_style(tester, 'Plain one').color, _colors(tester).text);
      expect(_style(tester, 'Plain two').color, _colors(tester).text);
      await tester.tap(find.text('Plain two'));
      await tester.pump();
      expect(app.backend.position, const Duration(milliseconds: 5000));

      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      expect(find.text(_l10n.lyricsSyncOffset), findsNothing);
    });

    testWidgets('offline, lyrics never downloaded show C07 with Try again', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository(
        lyrics: BundledLyricsRepository(DiskAssetBundle()),
      );
      await _pump(
        tester,
        catalog: catalog,
        failAfterStart: const NetworkFailure('offline'),
      );

      final state = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(state.kind, EmptyStateKind.offline);
      expect(find.text(_l10n.lyricsOfflineTitle), findsOneWidget);
      expect(find.text(_l10n.lyricsOfflineMessage), findsOneWidget);
      expect(find.text(_first), findsNothing);

      // Still offline: Try again asks again and keeps the state.
      final calls = catalog.songCalls.length;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await _settle(tester);
      expect(catalog.songCalls.length, calls + 1);
      expect(find.text(_l10n.lyricsOfflineTitle), findsOneWidget);

      // Back online: Try again shows the lyrics.
      catalog.failure = null;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await _settle(tester);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text(_first), findsOneWidget);
    });

    testWidgets('offline, the panel under the artwork says why', (
      tester,
    ) async {
      await _pump(
        tester,
        catalog: FakeCatalogRepository(
          lyrics: BundledLyricsRepository(DiskAssetBundle()),
        ),
        failAfterStart: const NetworkFailure('offline'),
        lyricsMode: false,
      );

      expect(find.byType(LyricsPreview), findsOneWidget);
      expect(find.text(_l10n.lyricsPreviewOffline), findsOneWidget);
      expect(find.text(_l10n.playerNoLyrics), findsNothing);

      // Tapping it opens the lyrics, where Try again is.
      await tester.tap(find.byType(LyricsPreview));
      await _settle(tester);
      expect(find.text(_l10n.lyricsOfflineTitle), findsOneWidget);
    });

    testWidgets('another failure shows the C07 error state', (tester) async {
      await _pump(
        tester,
        catalog: FakeCatalogRepository(
          lyrics: BundledLyricsRepository(DiskAssetBundle()),
        ),
        failAfterStart: const BackendFailure('refused'),
      );

      final state = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(state.kind, EmptyStateKind.error);
      expect(find.text(_l10n.lyricsLoadFailedTitle), findsOneWidget);
      expect(find.text(_l10n.actionTryAgain), findsOneWidget);
    });

    testWidgets('lyrics downloaded once still show offline', (tester) async {
      final catalog = FakeCatalogRepository(
        lyrics: BundledLyricsRepository(DiskAssetBundle()),
      );
      final db = memoryDatabase();
      await tester.runAsync(() => cacheSampleLyrics(db));
      await _pump(
        tester,
        catalog: catalog,
        database: db,
        failAfterStart: const NetworkFailure('offline'),
      );

      expect(find.text(_first), findsOneWidget);
      expect(catalog.songCalls, isEmpty);
    });

    testWidgets('an unlinked song offers Match lyrics', (tester) async {
      await _pump(tester, titles: const ['Kidus']);

      expect(find.text(_l10n.playerNoLyrics), findsOneWidget);
      await tester.tap(find.text(_l10n.songMatchLyrics));
      await _settle(tester);
      expect(find.byType(MatchLyricsSheet), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets('fits at 1.3× text in ${brightness.name} mode', (
        tester,
      ) async {
        final app = await _pump(
          tester,
          titles: const ['ብርሃን ሆንልን'],
          textScale: 1.3,
          phoneBrightness: brightness,
        );
        await app.at(tester, 20000);
        await tester.tap(find.byTooltip(_l10n.lyricsOptions));
        await _settle(tester);
        await tester.tap(find.text(_l10n.lyricsShowTransliteration));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Report wrong lyrics in the options opens the report sheet '
        'for the song and recording shown', (tester) async {
      final catalog = FakeCatalogRepository(
        lyrics: BundledLyricsRepository(DiskAssetBundle()),
      );
      await _pump(tester, catalog: catalog);
      await tester.tap(find.byTooltip(_l10n.lyricsOptions));
      await _settle(tester);
      await tester.ensureVisible(find.text(_l10n.reportLyrics));
      await tester.tap(find.text(_l10n.reportLyrics));
      await _settle(tester);

      // The options closed; only the report sheet is open.
      expect(find.text(_l10n.lyricsShowTransliteration), findsNothing);
      expect(find.byType(ReportLyricsSheet), findsOneWidget);
      await tester.tap(find.text(_l10n.reportReasonWrongTiming));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, _l10n.reportSend));
      await _settle(tester);

      expect(find.text(_l10n.reportSent), findsOneWidget);
      final sent = catalog.reports.single;
      expect(sent.songId, 'galatoomi');
      expect(sent.recordingId, 'galatoomi');
      expect(sent.reason, ReportReason.wrongTiming);
    });
  });

  group('The user\'s own contribution', () {
    const own = Song(
      id: 'galatoomi-2',
      title: 'Galatoomi',
      sections: [
        LyricSection(
          id: 'v1',
          kind: SectionKind.verse,
          lines: [LyricLine('Own line one'), LyricLine('Own line two')],
        ),
      ],
      playOrder: ['v1'],
    );

    Future<void> addCopy(
      WidgetTester tester,
      ZemaDatabase db,
      String title,
    ) async {
      final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
      await tester.runAsync(
        () => db.ownCopiesDao.add(
          OwnCopy(
            contributionId: 'c-1',
            kind: ContributionKind.newSong,
            song: own,
            recording: const Recording(
              id: 'rec-own',
              songId: 'galatoomi-2',
              source: RecordingSource.localFile,
              fileName: 'Galatoomi.mp3',
            ),
            timing: const SyncTiming(
              recordingId: 'rec-own',
              starts: [Duration(seconds: 1), Duration(seconds: 5)],
            ),
            trackId: tracks.firstWhere((t) => t.title == title).id,
            submittedAt: DateTime.utc(2026, 11, 2),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('shows on its track, synced and marked Pending review, '
        'until it is reviewed', (tester) async {
      final db = memoryDatabase();
      final app = await _pump(tester, database: db);
      expect(find.text(_first), findsOneWidget);
      expect(find.text(_l10n.lyricsPendingReview), findsNothing);

      await addCopy(tester, db, 'Galatoomi');
      expect(find.text(_first), findsNothing);
      expect(find.text('Own line one'), findsOneWidget);
      expect(find.text(_l10n.lyricsPendingReview), findsOneWidget);
      await app.at(tester, 6000);
      expect(
        _style(tester, 'Own line two').color,
        _colors(tester).primaryText,
        reason: 'its own timings',
      );

      // Rejected: the track goes back to the catalog's song.
      await tester.runAsync(() => db.ownCopiesDao.remove('c-1'));
      await _settle(tester);
      expect(find.text(_first), findsOneWidget);
      expect(find.text(_l10n.lyricsPendingReview), findsNothing);
    });

    testWidgets('another track does not show it', (tester) async {
      final db = memoryDatabase();
      await _pump(tester, titles: const ['Galatoomi', 'Kidus'], database: db);
      await addCopy(tester, db, 'Kidus');
      expect(find.text(_first), findsOneWidget);
      expect(find.text(_l10n.lyricsPendingReview), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('the mark fits at 1.3× text in ${brightness.name} mode', (
        tester,
      ) async {
        final db = memoryDatabase();
        await _pump(
          tester,
          database: db,
          size: const Size(360, 640),
          textScale: 1.3,
          phoneBrightness: brightness,
        );
        await addCopy(tester, db, 'Galatoomi');
        expect(find.text(_l10n.lyricsPendingReview), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
