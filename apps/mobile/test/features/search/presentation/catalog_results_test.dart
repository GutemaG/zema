import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/presentation/song_detail_screen.dart';
import 'package:zema/features/search/application/catalog_search.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/bundled_lyrics_repository.dart';
import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_lyrics.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// A line of the sample "ብርሃን ሆንልን", as the server answers it.
const _birhanLine = CatalogSearchHit(
  songId: 'birhan-honlin',
  title: 'ብርሃን ሆንልን',
  artist: 'Zema Samples',
  score: 0.95,
  line: 'በጨለማ መንገድ ምራን',
  lineTransliteration: 'Bechelema menged miran',
);

/// Lets asset loading and database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Search, with a phone track "Selam" and the sample catalog's index
/// saved. With [cached], the sample lyrics are downloaded. [failAfterStart]
/// makes every catalog call fail once the index is saved.
Future<FakeCatalogRepository> _pump(
  WidgetTester tester, {
  bool cached = false,
  ZemaFailure? failAfterStart,
  bool backendConfigured = true,
}) async {
  useScreen(tester, size: const Size(400, 1200));
  final catalog = FakeCatalogRepository(
    lyrics: BundledLyricsRepository(DiskAssetBundle()),
  );
  final db = memoryDatabase();
  if (cached) await tester.runAsync(() => cacheSampleLyrics(db));
  await pumpZemaApp(
    tester,
    location: AppRoutes.search,
    libraryScanner: FakeLibraryScanner([
      scannedAudio(1, '/m/1.mp3', title: 'Selam', artist: 'Choir'),
      scannedAudio(2, '/m/2.mp3', title: 'Galatoomi', artist: 'Zema Samples'),
    ]),
    database: db,
    catalog: catalog,
    backendConfigured: backendConfigured,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  await _settle(tester);
  catalog.failure = failAfterStart;
  return catalog;
}

/// Types [query] and draws one frame, without waiting for the server.
Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
}

/// Waits out the debounce and lets the answer show.
Future<void> _answer(WidgetTester tester) async {
  await tester.pump(lineSearchDelay);
  await _settle(tester);
}

Finder _row(String text) => find.descendant(
  of: find.byType(ListTile),
  matching: find.textContaining(text, findRichText: true),
);

Finder get _offlineNote => find.text(_l10n.searchCatalogOffline);
Finder get _failedNote => find.text(_l10n.searchCatalogFailed);
Finder get _tryAgain => find.widgetWithText(TextButton, _l10n.actionTryAgain);

void main() {
  testWidgets('phone results and catalog titles show at once, before the '
      'server is asked', (tester) async {
    final catalog = await _pump(tester);
    await _type(tester, 'selam');

    expect(find.widgetWithText(ListTile, 'ሰላም ለዚህ ቤት'), findsOneWidget);
    expect(find.text(_l10n.searchScopeSongs), findsWidgets);
    expect(find.text('Selam'), findsOneWidget); // the phone track
    expect(catalog.searchCalls, isEmpty);

    await tester.pump(lineSearchDelay - const Duration(milliseconds: 1));
    expect(catalog.searchCalls, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(catalog.searchCalls, ['selam']);
    await _settle(tester);
  });

  testWidgets('online, a line from a song never downloaded is found and '
      'opens it', (tester) async {
    final catalog = await _pump(tester);
    catalog.searchHits['bechelema'] = [_birhanLine];
    await _type(tester, 'bechelema');
    expect(_row('በጨለማ'), findsNothing);

    await _answer(tester);
    expect(find.widgetWithText(ListTile, 'ብርሃን ሆንልን'), findsOneWidget);
    expect(_row('በጨለማ መንገድ ምራን'), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);

    await tester.tap(_row('በጨለማ መንገድ ምራን'));
    await _settle(tester);
    expect(find.byType(SongDetailScreen), findsOneWidget);
    expect(catalog.songCalls, contains('birhan-honlin'));
    expect(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/search/song?id=birhan-honlin',
    );
  });

  testWidgets('typing on sends only the last query', (tester) async {
    final catalog = await _pump(tester);
    await _type(tester, 'bech');
    await tester.pump(const Duration(milliseconds: 200));
    await _type(tester, 'bechelema');
    await _answer(tester);
    expect(catalog.searchCalls, ['bechelema']);
  });

  testWidgets('a late answer for an earlier query is never shown', (
    tester,
  ) async {
    final catalog = await _pump(tester);
    final gate = catalog.searchGate = Completer<void>();
    catalog.searchHits['bechelema'] = [_birhanLine];
    await _type(tester, 'bechelema');
    await tester.pump(lineSearchDelay);
    expect(catalog.searchCalls, ['bechelema']);

    await _type(tester, 'zzqqxx');
    await tester.pump(lineSearchDelay);
    expect(catalog.searchCalls, ['bechelema', 'zzqqxx']);
    gate.complete();
    await _settle(tester);

    expect(_row('በጨለማ'), findsNothing);
    expect(find.text(_l10n.libraryNoResultsTitle), findsOneWidget);
  });

  testWidgets('offline, the note shows above downloaded lines; phone results '
      'are unaffected', (tester) async {
    final catalog = await _pump(
      tester,
      cached: true,
      failAfterStart: const NetworkFailure('offline'),
    );
    await _type(tester, 'jaallatee');
    // Downloaded lines show after one database read, before the server is
    // asked.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(_row('Waaqayyo nu jaallatee'), findsOneWidget);
    expect(catalog.searchCalls, isEmpty);

    await _answer(tester);
    expect(_offlineNote, findsOneWidget);
    expect(_tryAgain, findsOneWidget);
    expect(_row('Waaqayyo nu jaallatee'), findsOneWidget);

    await _type(tester, 'selam');
    await _answer(tester);
    expect(find.text('Selam'), findsOneWidget); // the phone track
    expect(find.widgetWithText(ListTile, 'ሰላም ለዚህ ቤት'), findsOneWidget);
    expect(_offlineNote, findsOneWidget);
  });

  testWidgets('offline with nothing found, the note shows instead of "No '
      'results"', (tester) async {
    await _pump(tester, failAfterStart: const NetworkFailure('offline'));
    await _type(tester, 'zzqqxx');
    await _answer(tester);
    expect(_offlineNote, findsOneWidget);
    expect(find.text(_l10n.libraryNoResultsTitle), findsNothing);
  });

  testWidgets('a server error shows its note; Try again asks again', (
    tester,
  ) async {
    final catalog = await _pump(
      tester,
      failAfterStart: const BackendFailure('500'),
    );
    catalog.searchHits['bechelema'] = [_birhanLine];
    await _type(tester, 'bechelema');
    await _answer(tester);
    expect(_failedNote, findsOneWidget);
    expect(_offlineNote, findsNothing);
    expect(_row('በጨለማ'), findsNothing);

    catalog.failure = null;
    await tester.tap(_tryAgain);
    await _answer(tester);
    expect(catalog.searchCalls, ['bechelema', 'bechelema']);
    expect(_failedNote, findsNothing);
    expect(_row('በጨለማ መንገድ ምራን'), findsOneWidget);
  });

  testWidgets('a build with no backend shows no note, and phone results '
      'still work', (tester) async {
    // With no backend there is no index, so no lyrics either (bolt 024).
    await _pump(tester, cached: true, backendConfigured: false);
    await _type(tester, 'jaallatee');
    await _answer(tester);
    expect(_offlineNote, findsNothing);
    expect(_failedNote, findsNothing);
    expect(find.text(_l10n.libraryNoResultsTitle), findsOneWidget);

    await _type(tester, 'selam');
    await _answer(tester);
    expect(find.text('Selam'), findsOneWidget);
    expect(_offlineNote, findsNothing);
  });

  testWidgets('the Lyrics chip shows all catalog matches, without phone '
      'songs', (tester) async {
    final catalog = await _pump(tester);
    catalog.searchHits['selam'] = [
      const CatalogSearchHit(
        songId: 'birhan-honlin',
        title: 'ብርሃን ሆንልን',
        score: 0.8,
        line: 'Selam line',
      ),
    ];
    await _type(tester, 'selam');
    await _answer(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, _l10n.searchScopeLyrics));
    await tester.pumpAndSettle();

    expect(find.text('Selam'), findsNothing); // the phone track
    expect(find.widgetWithText(ListTile, 'ሰላም ለዚህ ቤት'), findsOneWidget);
    expect(_row('Selam line'), findsOneWidget);
  });
}
