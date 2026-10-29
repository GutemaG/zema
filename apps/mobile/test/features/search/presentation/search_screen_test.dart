import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/presentation/album_screen.dart';
import 'package:zema/features/library/presentation/artist_screen.dart';
import 'package:zema/features/library/presentation/library_screen.dart';
import 'package:zema/features/library/presentation/song_menu.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/search/application/recent_searches.dart';
import 'package:zema/features/search/presentation/search_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(
    1,
    '/m/1.mp3',
    title: 'ቅድስት ማርያም',
    artist: 'ዘማሪት ሰላም',
    album: 'ምስጋና',
  ),
  scannedAudio(2, '/m/2.mp3', title: 'ፀሎት', artist: 'Zerfe', album: 'Kidase'),
  scannedAudio(3, '/m/3.mp3', title: 'Amlak', artist: 'Zerfe', album: 'Kidase'),
  for (var i = 1; i <= 6; i++)
    scannedAudio(10 + i, '/m/k$i.mp3', title: 'Medhanit $i', artist: 'Choir'),
];

class _Search {
  _Search(this.db, this.handler);

  final ZemaDatabase db;
  final ZemaAudioHandler handler;
}

Future<_Search> _pump(
  WidgetTester tester, {
  List<String>? recent,
  FakeAudioPermissionService? permissions,
  bool explained = true,
  Brightness phoneBrightness = Brightness.dark,
  CatalogRepository? catalog,
  bool backendConfigured = true,
}) async {
  useScreen(tester, size: const Size(360, 1400));
  final db = memoryDatabase();
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: AppRoutes.search,
    libraryScanner: FakeLibraryScanner(_files()),
    permissions: permissions,
    database: db,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    catalog: catalog,
    backendConfigured: backendConfigured,
    savedPrefs: {
      LibraryAccessController.explainedKey: explained,
      RecentSearches.key: ?recent,
    },
  );
  return _Search(db, handler);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

/// The path of the page showing [page].
String _pathOf(WidgetTester tester, Type page) =>
    GoRouterState.of(tester.element(find.byType(page))).uri.path;

ChoiceChip _chip(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
);

void main() {
  group('Search', () {
    testWidgets('shows a hint before anything is typed', (tester) async {
      await _pump(tester);

      expect(find.text(_l10n.comingSoonTitle), findsNothing);
      expect(find.text(_l10n.searchHintTitle), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('finds Ethiopic titles with Latin letters while typing', (
      tester,
    ) async {
      await _pump(tester);

      await _type(tester, 'kidist');
      expect(_rowTitles(tester), ['ቅድስት ማርያም']);

      await _type(tester, 'tselot');
      expect(_rowTitles(tester), ['ፀሎት']);
    });

    testWidgets('groups songs, artists and albums', (tester) async {
      await _pump(tester);

      await _type(tester, 'zerfe');

      expect(find.text(_l10n.searchScopeSongs), findsOneWidget); // chip
      expect(find.text(_l10n.searchScopeArtists), findsNWidgets(2));
      expect(find.text(_l10n.searchScopeAlbums), findsNWidgets(2));
      expect(find.text('Zerfe'), findsWidgets);
      expect(find.text('Kidase'), findsOneWidget);
    });

    testWidgets('chips show one group; See all selects the chip', (
      tester,
    ) async {
      await _pump(tester);
      await _type(tester, 'medhanit');

      // All: the top 4 songs and See all.
      expect(_rowTitles(tester), hasLength(4));
      await tester.tap(find.text(_l10n.searchSeeAll).first);
      await tester.pumpAndSettle();
      expect(_chip(tester, _l10n.searchScopeSongs).selected, isTrue);
      expect(_rowTitles(tester), hasLength(6));

      final artists = find.widgetWithText(ChoiceChip, _l10n.searchScopeArtists);
      await tester.ensureVisible(artists);
      await tester.tap(artists);
      await tester.pumpAndSettle();
      expect(find.byType(TrackRow), findsNothing);
      expect(find.text(_l10n.libraryNoResultsTitle), findsOneWidget);

      final all = find.widgetWithText(ChoiceChip, _l10n.searchScopeAll);
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), hasLength(4));
    });

    testWidgets('a song plays with the song results as the queue', (
      tester,
    ) async {
      final search = await _pump(tester);
      await _type(tester, 'medhanit');
      await tester.tap(find.widgetWithText(ChoiceChip, _l10n.searchScopeSongs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medhanit 3'));
      await tester.pumpAndSettle();

      final snapshot = search.handler.snapshot;
      expect(snapshot.current?.title, 'Medhanit 3');
      expect(snapshot.queue.map((t) => t.title), [
        for (var i = 1; i <= 6; i++) 'Medhanit $i',
      ]);
      expect(find.byType(SongMenuButton), findsNWidgets(6));
    });

    testWidgets('an artist opens in Search; Back returns to the results', (
      tester,
    ) async {
      await _pump(tester);
      await _type(tester, 'choir');

      await tester.tap(find.text('Choir'));
      await tester.pumpAndSettle();
      expect(find.byType(ArtistScreen), findsOneWidget);
      expect(
        _pathOf(tester, ArtistScreen),
        '${AppRoutes.search}/${AppRoutes.artistPath}',
      );
      expect(find.byType(LibraryScreen, skipOffstage: false), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('choir'), findsOneWidget);
      expect(find.text('Choir'), findsOneWidget);
    });

    testWidgets('an album opens in Search', (tester) async {
      await _pump(tester);
      await _type(tester, 'kidase');

      await tester.tap(find.text('Kidase'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(
        _pathOf(tester, AlbumScreen),
        '${AppRoutes.search}/${AppRoutes.albumPath}',
      );
      expect(find.byType(LibraryScreen, skipOffstage: false), findsNothing);
    });

    testWidgets('no results shows the empty state', (tester) async {
      await _pump(tester);

      await _type(tester, 'zzzzqqq');

      final state = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(state.title, _l10n.libraryNoResultsTitle);
    });

    testWidgets('hidden songs are not found', (tester) async {
      final search = await _pump(tester);
      final amlak = (await tester.runAsync(search.db.libraryDao.allTracks))!
          .firstWhere((t) => t.title == 'Amlak');
      await search.db.libraryDao.hideTracks([amlak.id]);
      await tester.pumpAndSettle();

      await _type(tester, 'amlak');

      expect(find.byType(TrackRow), findsNothing);
    });

    testWidgets('asks for audio access like Library', (tester) async {
      await _pump(
        tester,
        permissions: FakeAudioPermissionService(current: AudioAccess.denied),
        explained: false,
      );

      expect(find.text(_l10n.libraryAccessTitle), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('fits at 1.3× on a small phone, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          recent: ['ቅዱስ ሚካኤል ሊቀ መላእክት ዘሰማይ ወምድር'],
          phoneBrightness: brightness,
        );
        useScreen(tester, size: const Size(320, 640), textScale: 1.3);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness recent');

        await _type(tester, 'zerfe');
        expect(tester.takeException(), isNull, reason: '$brightness results');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('Recent searches', () {
    testWidgets('the search key saves the query', (tester) async {
      await _pump(tester);
      await _type(tester, 'kidist');

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_l10n.libraryClearSearch));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.searchRecentHeading), findsOneWidget);
      expect(find.text('kidist'), findsOneWidget);
    });

    testWidgets('opening a result saves the query; typing alone does not', (
      tester,
    ) async {
      final prefs = await () async {
        await _pump(tester);
        return savedPreferences();
      }();
      await _type(tester, 'amlak');
      expect(prefs.getStringList(RecentSearches.key), isNull);

      await tester.tap(find.text('Amlak'));
      await tester.pumpAndSettle();

      expect(prefs.getStringList(RecentSearches.key), ['amlak']);
    });

    testWidgets('a recent search searches again', (tester) async {
      await _pump(tester, recent: ['tselot', 'amlak']);

      expect(find.text('tselot'), findsOneWidget);
      await tester.tap(find.text('tselot'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'tselot',
      );
      expect(_rowTitles(tester), ['ፀሎት']);
    });

    testWidgets('remove one and Clear all', (tester) async {
      await _pump(tester, recent: ['tselot', 'amlak']);

      await tester.tap(find.byTooltip(_l10n.searchRemoveRecent('tselot')));
      await tester.pumpAndSettle();
      expect(find.text('tselot'), findsNothing);
      expect(find.text('amlak'), findsOneWidget);

      await tester.tap(find.text(_l10n.searchClearRecent));
      await tester.pumpAndSettle();
      expect(find.text('amlak'), findsNothing);
      expect(find.text(_l10n.searchHintTitle), findsOneWidget);
    });
  });

  group('Pull to refresh', () {
    Future<void> pull(WidgetTester tester, Finder from) async {
      await tester.fling(from, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('refreshes the song list from the recent searches', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository(
        entries: [catalogEntry(const Song(id: 'a', title: 'A', sections: []))],
      );
      final search = await _pump(tester, catalog: catalog);
      expect(catalog.indexCalls, 1, reason: 'the start-up refresh');
      catalog.entries = [
        ...catalog.entries,
        catalogEntry(const Song(id: 'b', title: 'B', sections: [])),
      ];

      await pull(tester, find.byType(EmptyState));

      expect(catalog.indexCalls, 2, reason: 'forced, though recent');
      expect((await tester.runAsync(search.db.catalogDao.count))!, 2);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('refreshes from the results too', (tester) async {
      final catalog = FakeCatalogRepository();
      await _pump(tester, catalog: catalog);
      await tester.enterText(find.byType(TextField), 'amlak');
      await tester.pumpAndSettle();

      await pull(tester, find.byType(TrackRow).first);

      expect(catalog.indexCalls, 2);
    });

    testWidgets('a failure shows a short message and keeps the list', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository(
        entries: [catalogEntry(const Song(id: 'a', title: 'A', sections: []))],
      );
      final search = await _pump(tester, catalog: catalog);
      catalog.failure = const NetworkFailure('offline');

      await pull(tester, find.byType(EmptyState));

      expect(find.text(_l10n.catalogRefreshFailed), findsOneWidget);
      expect((await tester.runAsync(search.db.catalogDao.count))!, 1);
    });

    testWidgets('the list springs back to the top after a pull', (
      tester,
    ) async {
      await _pump(tester, recent: ['amlak']);
      final header = find.text(_l10n.searchRecentHeading);
      final before = tester.getTopLeft(header);

      await pull(tester, header);

      expect(tester.getTopLeft(header), before);
    });

    testWidgets('a build without a backend says so', (tester) async {
      await _pump(tester, backendConfigured: false);

      await pull(tester, find.byType(EmptyState));

      expect(find.text(_l10n.catalogNotConfigured), findsOneWidget);
    });
  });
}
