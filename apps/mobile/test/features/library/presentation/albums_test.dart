import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/album_grouping.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_groups.dart';
import 'package:zema/features/library/presentation/album_screen.dart';
import 'package:zema/features/library/presentation/widgets/album_tile.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(
    1,
    '/m/1.mp3',
    title: 'Amlak',
    artist: 'Zerfe',
    album: 'Mezmur Vol. 1',
    trackNumber: 2,
    year: 2019,
    durationMs: 75000,
  ),
  scannedAudio(
    2,
    '/m/2.mp3',
    title: 'Kidus',
    artist: 'ዘማሪት',
    album: 'Mezmur Vol. 1',
    trackNumber: 1,
    year: 2019,
    durationMs: 105000,
  ),
  scannedAudio(
    3,
    '/m/3.mp3',
    title: 'ሰላም ለኪ',
    artist: 'Choir member',
    albumArtist: 'ሊቀ መዘምራን',
    album: 'የቅዱሳን መዝሙር',
    year: 2021,
  ),
  scannedAudio(4, '/m/4.mp3', title: 'Untagged', artist: 'Mahlet'),
];

Future<ZemaAudioHandler> _pump(
  WidgetTester tester, {
  List<ScannedAudio>? files,
  String? location,
  Map<String, Object> savedPrefs = const {},
  Brightness phoneBrightness = Brightness.dark,
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: location ?? AppRoutes.library,
    libraryScanner: FakeLibraryScanner(files ?? _files()),
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true, ...savedPrefs},
  );
  if (location == null) {
    // The tab bar scrolls: on narrow screens the tab may start off-screen.
    await tester.ensureVisible(find.text(_l10n.libraryTabAlbums));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.libraryTabAlbums));
    await tester.pumpAndSettle();
  }
  return handler;
}

List<String> _tileTitles(WidgetTester tester) => [
  for (final tile in tester.widgetList<AlbumTile>(find.byType(AlbumTile)))
    tile.album.title ?? '?',
];

Future<void> _choose(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(_l10n.librarySortTooltip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Albums', () {
    testWidgets('a grid of albums with name and artist, two columns', (
      tester,
    ) async {
      useScreen(tester);
      await _pump(tester);

      expect(find.text(_l10n.albumCount(3)), findsOneWidget);
      expect(_tileTitles(tester), ['Mezmur Vol. 1', 'የቅዱሳን መዝሙር', '?']);
      expect(find.text(_l10n.variousArtists), findsOneWidget);
      expect(find.text('ሊቀ መዘምራን'), findsOneWidget);
      expect(find.text(_l10n.unknownAlbum), findsOneWidget);
      final tiles = find.byType(AlbumTile);
      expect(
        tester.getTopLeft(tiles.at(0)).dy,
        tester.getTopLeft(tiles.at(1)).dy,
      );
      expect(
        tester.getTopLeft(tiles.at(2)).dy,
        greaterThan(tester.getTopLeft(tiles.at(0)).dy),
      );
    });

    testWidgets('more columns on a wide screen', (tester) async {
      useScreen(tester, size: const Size(800, 900));
      await _pump(tester);

      final tiles = find.byType(AlbumTile);
      expect(
        tester.getTopLeft(tiles.at(2)).dy,
        tester.getTopLeft(tiles.at(0)).dy,
      );
    });

    testWidgets('sorts by year and remembers it', (tester) async {
      await _pump(tester);

      await _choose(tester, _l10n.sortYear);
      await _choose(tester, _l10n.sortDescending);

      expect(_tileTitles(tester), ['የቅዱሳን መዝሙር', 'Mezmur Vol. 1', '?']);
      final prefs = await savedPreferences();
      expect(prefs.getString(AlbumSortController.fieldKey), 'year');
      expect(prefs.getBool(AlbumSortController.descendingKey), isTrue);
    });

    testWidgets('a saved sort is used at launch', (tester) async {
      await _pump(
        tester,
        savedPrefs: {
          AlbumSortController.fieldKey: 'artist',
          AlbumSortController.descendingKey: false,
        },
      );

      // Unknown album's only artist is Mahlet; "Various artists" goes last.
      expect(_tileTitles(tester), ['?', 'የቅዱሳን መዝሙር', 'Mezmur Vol. 1']);
    });

    testWidgets('an album shows its details and numbered songs', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 900));
      await _pump(tester);

      await tester.tap(find.text('Mezmur Vol. 1'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(find.text(_l10n.variousArtists), findsOneWidget);
      expect(find.text('2019 · 2 songs · 3 min'), findsOneWidget);
      final rows = tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();
      expect([for (final r in rows) r.track.title], ['Kidus', 'Amlak']);
      expect([for (final r in rows) r.number], [1, 2]);
    });

    testWidgets('Play plays the album in order; a row plays from there', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 900));
      final handler = await _pump(tester);
      await tester.tap(find.text('Mezmur Vol. 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(
        [for (final t in handler.snapshot.queue) t.title],
        ['Kidus', 'Amlak'],
      );

      await tester.tap(find.text('Amlak').first);
      await tester.pumpAndSettle();
      expect(handler.snapshot.current?.title, 'Amlak');
    });

    testWidgets('"Unknown album" holds songs without an album', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(_l10n.unknownAlbum));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TrackRow, 'Untagged'), findsOneWidget);
      expect(find.text('Mahlet'), findsOneWidget, reason: 'single artist');
    });

    testWidgets('an album no longer in the library shows C07', (tester) async {
      await _pump(tester, location: AppRoutes.album(const AlbumId('Nope')));

      expect(find.text(_l10n.albumGoneTitle), findsOneWidget);
    });

    testWidgets('an empty library shows C07', (tester) async {
      await _pump(tester, files: const []);

      expect(find.text(_l10n.albumsEmptyTitle), findsOneWidget);
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pump(tester, phoneBrightness: brightness);
        expect(tester.takeException(), isNull, reason: '$brightness grid');
        await tester.tap(find.text('Mezmur Vol. 1'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness album');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('formatTotalDuration', () {
    test('minutes under an hour, hours and minutes after', () {
      expect(
        formatTotalDuration(_l10n, const Duration(minutes: 47, seconds: 40)),
        '48 min',
      );
      expect(
        formatTotalDuration(_l10n, const Duration(hours: 1, minutes: 12)),
        '1 h 12 min',
      );
    });
  });
}
