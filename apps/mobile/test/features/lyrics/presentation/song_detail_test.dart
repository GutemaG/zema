import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/not_found_screen.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/presentation/song_detail_screen.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/bundled_lyrics_repository.dart';
import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_lyrics.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

FakeCatalogRepository _catalog() =>
    FakeCatalogRepository(lyrics: BundledLyricsRepository(DiskAssetBundle()));

/// Lets asset loading and database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// The app on Library with the sample Galatoomi track (linked) and an
/// unlinked one. With [cached], the sample lyrics are already downloaded.
Future<ZemaAudioHandler> _pump(
  WidgetTester tester, {
  double textScale = 1,
  Brightness phoneBrightness = Brightness.dark,
  bool cached = false,
  FakeCatalogRepository? catalog,
  ZemaFailure? failAfterStart,
}) async {
  useScreen(tester, size: const Size(400, 860), textScale: textScale);
  final handler = fakeAudioHandler(FakeAudioBackend());
  final db = memoryDatabase();
  if (cached) await tester.runAsync(() => cacheSampleLyrics(db));
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner([
      scannedAudio(1, '/m/1.mp3', title: 'Galatoomi', artist: 'Zema Samples'),
      scannedAudio(2, '/m/2.mp3', title: 'Kidus'),
    ]),
    database: db,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    catalog: catalog,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  await _settle(tester);
  // The index is saved; downloading lyrics fails from here on.
  catalog?.failure = failAfterStart;
  return handler;
}

void _go(WidgetTester tester, String location) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

Finder _resultLine(String text) => find.descendant(
  of: find.byType(ListTile),
  matching: find.textContaining(text, findRichText: true),
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.tap(find.text('Search').last);
  await _settle(tester);
  await tester.enterText(find.byType(TextField), query);
  await _settle(tester);
}

void main() {
  group('Lyric search', () {
    testWidgets('a Lyrics group shows the song with its matching line', (
      tester,
    ) async {
      await _pump(tester, cached: true);
      await _search(tester, 'jaallatee');

      expect(find.text(_l10n.searchScopeLyrics), findsWidgets);
      expect(find.text('Galatoomi'), findsWidgets);
      final line = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.textSpan?.toPlainText().contains('jaallatee') ?? false),
        ),
      );
      final spans = (line.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.map((s) => s.text).join(), 'Waaqayyo nu jaallatee');
      expect(spans.last.style?.fontWeight, FontWeight.w700);
      expect(spans.first.style, isNull);
    });

    testWidgets('a chorus line sung three times finds its song once', (
      tester,
    ) async {
      await _pump(tester, cached: true);
      await _search(tester, 'maqaan ulfaatu');
      expect(
        find.textContaining('Maqaan kee haa ulfaatu', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the Lyrics chip shows only lyric matches', (tester) async {
      await _pump(tester, cached: true);
      await _search(tester, 'galatoomi');
      // The track (Songs) and the lyrics (Lyrics) both match.
      expect(find.text(_l10n.searchScopeSongs), findsNWidgets(2));

      await tester.tap(
        find.widgetWithText(ChoiceChip, _l10n.searchScopeLyrics),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l10n.searchScopeSongs), findsOneWidget); // chip only
      // The title matches as well as the chorus, and the title wins a tie
      // (as on the server), so the row shows the artist, once.
      final row = find.widgetWithText(ListTile, 'Galatoomi');
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('Zema Samples')),
        findsOneWidget,
      );
    });

    testWidgets('a result opens Song detail in the Search tab', (tester) async {
      await _pump(tester, cached: true);
      await _search(tester, 'jaallatee');
      await tester.tap(_resultLine('jaallatee'));
      await _settle(tester);

      expect(find.byType(SongDetailScreen), findsOneWidget);
      expect(_location(tester), '/search/song?id=galatoomi');
    });
  });

  group('Song detail', () {
    testWidgets('header, lyrics with chorus and repeat markers', (
      tester,
    ) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('galatoomi'));
      await _settle(tester);

      expect(find.text('Galatoomi'), findsWidgets);
      expect(find.text('Zema Samples · Zema Samples'), findsOneWidget);
      expect(find.text(_l10n.playerPlay), findsOneWidget);
      // Each section once; the chorus's two later repeats are markers.
      expect(find.text('Galatoomi, galatoomi'), findsOneWidget);
      expect(find.text(_l10n.lyricsChorus), findsOneWidget);
      expect(
        find.text(_l10n.lyricsRepeat(_l10n.lyricsChorus)),
        findsNWidgets(2),
      );
    });

    testWidgets('Play plays the linked track', (tester) async {
      final handler = await _pump(tester);
      _go(tester, AppRoutes.song('galatoomi'));
      await _settle(tester);

      await tester.tap(find.text(_l10n.playerPlay));
      await _settle(tester);
      expect(handler.snapshot.current?.title, 'Galatoomi');
    });

    testWidgets('favorite toggles for the linked track', (tester) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('galatoomi'));
      await _settle(tester);

      await tester.tap(find.byTooltip(_l10n.songFavorite));
      await _settle(tester);
      expect(find.byTooltip(_l10n.songUnfavorite), findsOneWidget);
    });

    testWidgets('a song with no track on the phone hides Play', (tester) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('selam-lezih-bet'));
      await _settle(tester);

      expect(find.text(_l10n.songDetailNotOnPhone), findsOneWidget);
      expect(find.text(_l10n.playerPlay), findsNothing);
      expect(find.byTooltip(_l10n.songFavorite), findsNothing);
    });

    testWidgets('A+ grows the lyrics; transliteration shows when on', (
      tester,
    ) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('birhan-honlin'));
      await _settle(tester);
      double size() =>
          tester.widget<Text>(find.text('ጌታ ሆይ ብርሃን ሆንልን')).style!.fontSize!;
      final before = size();

      await tester.tap(find.byTooltip(_l10n.lyricsTextLarger));
      await tester.tap(find.byTooltip(_l10n.lyricsTextLarger));
      await tester.pumpAndSettle();
      expect(size(), closeTo(before * 1.2, 0.01));
      expect(find.text('Geta hoy birhan honlin'), findsNothing);
      // The song's title transliteration shows in the header.
      expect(find.text('Birhan Honlin'), findsOneWidget);
    });

    testWidgets('the Info tab shows album, artist and source', (tester) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('galatoomi'));
      await _settle(tester);

      await tester.tap(find.text(_l10n.songDetailInfoTab));
      await _settle(tester);
      expect(find.text(_l10n.songDetailAlbum), findsOneWidget);
      expect(find.text(_l10n.songSourceBundled), findsOneWidget);
    });

    testWidgets('an unknown or missing ID shows not found', (tester) async {
      await _pump(tester);
      _go(tester, AppRoutes.song('no-such-song'));
      await _settle(tester);
      expect(find.byType(NotFoundScreen), findsOneWidget);

      _go(tester, '${AppRoutes.library}/${AppRoutes.songPath}');
      await _settle(tester);
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('opening a song downloads its lyrics', (tester) async {
      final catalog = _catalog();
      await _pump(tester, catalog: catalog);
      expect(catalog.songCalls, isNot(contains('selam-lezih-bet')));

      _go(tester, AppRoutes.song('selam-lezih-bet'));
      await _settle(tester);

      expect(catalog.songCalls, contains('selam-lezih-bet'));
      expect(find.byType(SongDetailScreen), findsOneWidget);
      expect(find.text(_l10n.songDetailLyricsTab), findsOneWidget);
    });

    testWidgets('offline, a song never downloaded shows C07 with Try again', (
      tester,
    ) async {
      final catalog = _catalog();
      await _pump(
        tester,
        catalog: catalog,
        failAfterStart: const NetworkFailure('offline'),
      );
      _go(tester, AppRoutes.song('selam-lezih-bet'));
      await _settle(tester);

      final state = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(state.kind, EmptyStateKind.offline);
      expect(find.text(_l10n.lyricsOfflineTitle), findsOneWidget);
      expect(find.byType(NotFoundScreen), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);

      catalog.failure = null;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await _settle(tester);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text(_l10n.songDetailLyricsTab), findsOneWidget);
    });

    testWidgets('View lyrics in the song menu opens it', (tester) async {
      await _pump(tester);
      await tester.tap(find.byTooltip(_l10n.songMenu('Galatoomi')).first);
      await _settle(tester);
      await tester.tap(find.text(_l10n.songViewLyrics));
      await _settle(tester);
      expect(find.byType(SongDetailScreen), findsOneWidget);

      _go(tester, AppRoutes.library);
      await _settle(tester);
      await tester.tap(find.byTooltip(_l10n.songMenu('Kidus')).first);
      await _settle(tester);
      expect(find.text(_l10n.songViewLyrics), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('fits at 1.3× text in ${brightness.name} mode', (
        tester,
      ) async {
        await _pump(tester, textScale: 1.3, phoneBrightness: brightness);
        _go(tester, AppRoutes.song('birhan-honlin'));
        await _settle(tester);
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byTooltip(_l10n.lyricsTextLarger));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
