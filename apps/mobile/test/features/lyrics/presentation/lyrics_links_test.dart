import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_sync_controller.dart';
import 'package:zema/features/library/presentation/library_screen.dart';
import 'package:zema/features/lyrics/presentation/match_lyrics_sheet.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Two titles of the bundled sample songs (one with noise), and two that
/// match nothing.
List<ScannedAudio> _files() => [
  scannedAudio(1, '/m/1.mp3', title: 'ብርሃን ሆንልን', artist: 'Zema Samples'),
  scannedAudio(2, '/m/2.mp3', title: 'Galatoomi - Official Video 2020'),
  scannedAudio(3, '/m/3.mp3', title: 'Amlak'),
  scannedAudio(4, '/m/4.mp3', title: 'Kidus'),
];

class _App {
  _App(this.db, this.scanner, this.ids);

  final ZemaDatabase db;
  final FakeLibraryScanner scanner;

  /// Track IDs by title.
  final Map<String, int> ids;
}

Future<_App> _pump(WidgetTester tester, {double textScale = 1}) async {
  useScreen(tester, size: const Size(360, 1000), textScale: textScale);
  final db = memoryDatabase();
  final scanner = FakeLibraryScanner(_files());
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: scanner,
    database: db,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  // Asset loading and the database run outside the fake clock.
  await _settle(tester);
  final ids = {
    for (final t in (await tester.runAsync(db.libraryDao.allTracks))!)
      t.title: t.id,
  };
  return _App(db, scanner, ids);
}

/// Lets asset loading and database work, which run outside the fake clock,
/// finish, then settles the frames they cause.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LibraryScreen)));

Future<Map<int, (String?, bool)>> _rows(WidgetTester tester, _App app) async {
  final rows = (await tester.runAsync(
    () => app.db.lyricsLinksDao.watchLinks().first,
  ))!;
  return {for (final r in rows) r.trackId: (r.songId, r.manual)};
}

Future<String?> _linked(WidgetTester tester, _App app, String title) async =>
    (await _rows(tester, app))[app.ids[title]!]?.$1;

Future<void> _menu(WidgetTester tester, String title, String item) async {
  await tester.tap(find.byTooltip(_l10n.songMenu(title)).first);
  await _settle(tester);
  await tester.tap(find.text(item));
  await _settle(tester);
}

Future<void> _rescan(WidgetTester tester) async {
  await _container(tester).read(librarySyncProvider.notifier).sync();
  await _settle(tester);
}

void main() {
  group('Automatic lyrics links', () {
    testWidgets('link tracks whose titles match a song, and no others', (
      tester,
    ) async {
      final app = await _pump(tester);

      expect(await _linked(tester, app, 'ብርሃን ሆንልን'), 'birhan-honlin');
      expect(
        await _linked(tester, app, 'Galatoomi - Official Video 2020'),
        'galatoomi',
      );
      expect(await _linked(tester, app, 'Amlak'), isNull);
      expect(await _linked(tester, app, 'Kidus'), isNull);
      expect([
        for (final (_, manual) in (await _rows(tester, app)).values) manual,
      ], everyElement(isFalse));
    });

    testWidgets('a linked track offers Change and Unlink lyrics', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.byTooltip(_l10n.songMenu('ብርሃን ሆንልን')));
      await _settle(tester);

      expect(find.text(_l10n.songChangeLyrics), findsOneWidget);
      expect(find.text(_l10n.songUnlinkLyrics), findsOneWidget);
      expect(find.text(_l10n.songMatchLyrics), findsNothing);
    });
  });

  group('Match lyrics', () {
    testWidgets('picking a song links it by hand, with a snackbar', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _menu(tester, 'Amlak', _l10n.songMatchLyrics);
      expect(find.byType(MatchLyricsSheet), findsOneWidget);
      expect(find.text('ብርሃን ሆንልን'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(MatchLyricsSheet),
          matching: find.text('ሰላም ለዚህ ቤት'),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await _settle(tester);

      expect(find.byType(MatchLyricsSheet), findsNothing);
      expect(find.text(_l10n.songLyricsLinked('ሰላም ለዚህ ቤት')), findsOneWidget);
      expect(await _linked(tester, app, 'Amlak'), 'selam-lezih-bet');
      expect((await _rows(tester, app))[app.ids['Amlak']], (
        'selam-lezih-bet',
        true,
      ));
    });

    testWidgets('the picker searches and checks the linked song', (
      tester,
    ) async {
      await _pump(tester);

      await _menu(tester, 'ብርሃን ሆንልን', _l10n.songChangeLyrics);
      final sheet = find.byType(MatchLyricsSheet);
      final linked = tester.widget<ListTile>(
        find.ancestor(
          of: find.descendant(of: sheet, matching: find.text('ብርሃን ሆንልን')),
          matching: find.byType(ListTile),
        ),
      );
      expect(linked.selected, isTrue);

      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        'selam',
      );
      await _settle(tester);
      expect(
        find.descendant(of: sheet, matching: find.byType(ListTile)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('ሰላም ለዚህ ቤት')),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        'zzzzq',
      );
      await _settle(tester);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(_l10n.libraryNoResultsTitle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a manual link survives a rescan', (tester) async {
      final app = await _pump(tester);
      await _menu(tester, 'Amlak', _l10n.songMatchLyrics);
      await tester.tap(
        find.descendant(
          of: find.byType(MatchLyricsSheet),
          matching: find.text('Galatoomi'),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await _settle(tester);

      await _rescan(tester);

      expect(await _linked(tester, app, 'Amlak'), 'galatoomi');
    });
  });

  group('Unlink lyrics', () {
    testWidgets('stops the link, and matching does not bring it back', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _menu(tester, 'ብርሃን ሆንልን', _l10n.songUnlinkLyrics);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await _settle(tester);
      expect(find.text(_l10n.songLyricsUnlinked('ብርሃን ሆንልን')), findsOneWidget);
      expect(await _linked(tester, app, 'ብርሃን ሆንልን'), isNull);

      await _rescan(tester);

      expect(await _linked(tester, app, 'ብርሃን ሆንልን'), isNull);
      expect((await _rows(tester, app))[app.ids['ብርሃን ሆንልን']], (null, true));
      await tester.tap(find.byTooltip(_l10n.songMenu('ብርሃን ሆንልን')));
      await _settle(tester);
      expect(find.text(_l10n.songMatchLyrics), findsOneWidget);
    });
  });

  testWidgets('the picker fits at 1.3× in light and dark', (tester) async {
    for (final brightness in Brightness.values) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await _pump(tester, textScale: 1.3);
      await _menu(tester, 'Amlak', _l10n.songMatchLyrics);
      expect(tester.takeException(), isNull, reason: '$brightness');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
