import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema/features/home/presentation/widgets/continue_listening_card.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema/features/library/application/library_tab_request.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/presentation/auto_playlist_screen.dart';
import 'package:zema/features/library/presentation/playlist_screen.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/search/presentation/search_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

// Added yesterday, so they stay in Recently added (the last 30 days)
// whenever the tests run.
final _added = DateTime.now().toUtc().subtract(const Duration(days: 1));

List<ScannedAudio> _files() => [
  scannedAudio(
    1,
    '/m/1.mp3',
    title: 'Amlak',
    artist: 'Zerfe',
    dateAdded: _added,
  ),
  scannedAudio(
    2,
    '/m/2.mp3',
    title: 'Kidus',
    artist: 'Tewodros',
    dateAdded: _added,
  ),
  scannedAudio(
    3,
    '/m/3.mp3',
    title: 'Tselot',
    artist: 'Meskerem',
    dateAdded: _added,
  ),
];

class _Home {
  _Home(this.db, this.backend, this.handler, this.ids);

  final ZemaDatabase db;
  final FakeAudioBackend backend;
  final ZemaAudioHandler handler;

  /// Track IDs by title.
  final Map<String, int> ids;
}

/// Opens Home on a library of [files] after recording [plays] (titles,
/// oldest first) and creating [playlists] (name → titles).
Future<_Home> _pump(
  WidgetTester tester, {
  List<ScannedAudio>? files,
  List<String> plays = const [],
  Map<String, List<String>> playlists = const {},
  FakeLibraryScanner? scanner,
  FakeAudioPermissionService? permissions,
  bool explained = true,
  bool settle = true,
  Brightness phoneBrightness = Brightness.dark,
  Size size = const Size(360, 1200),
}) async {
  useScreen(tester, size: size);
  final db = memoryDatabase();
  final backend = FakeAudioBackend();
  final handler = fakeAudioHandler(backend);
  await pumpZemaApp(
    tester,
    libraryScanner: scanner ?? FakeLibraryScanner(files ?? _files()),
    permissions: permissions,
    database: db,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: explained},
    settle: settle,
  );
  if (!settle) {
    // A scan still running keeps a spinner going; pump a few frames.
    await tester.pump();
    await tester.pump();
    return _Home(db, backend, handler, const {});
  }
  final ids = {
    for (final t in (await tester.runAsync(db.libraryDao.allTracks))!)
      t.title: t.id,
  };
  final now = DateTime.now();
  for (final (i, title) in plays.indexed) {
    await db.historyDao.recordPlay(
      ids[title]!,
      at: now.subtract(Duration(hours: plays.length - i)),
    );
  }
  for (final MapEntry(key: name, value: titles) in playlists.entries) {
    final id = await db.collectionsDao.createPlaylist(name);
    await db.collectionsDao.addToPlaylist(id, [
      for (final t in titles) ids[t]!,
    ]);
  }
  await tester.pumpAndSettle();
  return _Home(db, backend, handler, ids);
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));

List<Track> _library(WidgetTester tester) =>
    _container(tester).read(libraryTracksProvider).value!;

/// Loads [title] (from the library list) and pauses it at [at], as the
/// player is after restoring the last queue.
Future<void> _pausedAt(
  WidgetTester tester,
  _Home home,
  String title,
  Duration at,
) async {
  final tracks = _library(tester);
  await home.handler.playTracks(
    tracks,
    start: tracks.indexWhere((t) => t.title == title),
  );
  await home.handler.pause();
  home.backend.advanceTo(at);
  await tester.pumpAndSettle();
}

/// The Library tab bar's selected tab.
LibraryTab _libraryTab(WidgetTester tester) =>
    LibraryTab.values[tester
        .widget<TabBar>(find.byType(TabBar))
        .controller!
        .index];

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> _backToHome(WidgetTester tester) async {
  await tester.tap(find.text(_l10n.navHome));
  await tester.pumpAndSettle();
}

void main() {
  group('Home', () {
    testWidgets('shows the sections in order and no Coming soon', (
      tester,
    ) async {
      final home = await _pump(
        tester,
        plays: ['Kidus', 'Amlak'],
        playlists: {
          'Timket': ['Tselot'],
        },
      );
      await _pausedAt(tester, home, 'Tselot', const Duration(seconds: 83));

      expect(find.text(_l10n.comingSoonTitle), findsNothing);
      final order = [
        _l10n.homeShuffleAll,
        _l10n.libraryTabFavorites,
        _l10n.autoRecentlyAdded,
        _l10n.libraryTabPlaylists,
        _l10n.homeContinueListening,
        _l10n.homeRecentlyPlayed,
        _l10n.homeYourPlaylists,
      ];
      Offset at(String text) => tester.getTopLeft(find.text(text).first);
      for (final (i, text) in order.indexed.skip(1)) {
        final previous = at(order[i - 1]);
        final current = at(text);
        // Quick actions sit two to a row; everything else stacks.
        expect(
          current.dy > previous.dy ||
              (current.dy == previous.dy && current.dx > previous.dx),
          isTrue,
          reason: '${order[i - 1]} before $text',
        );
      }
      expect(find.text(_l10n.homeResumeFrom('1:23')), findsOneWidget);
    });

    testWidgets('hides sections with nothing to show', (tester) async {
      await _pump(tester);

      expect(find.text(_l10n.homeShuffleAll), findsOneWidget);
      expect(find.text(_l10n.homeContinueListening), findsNothing);
      expect(find.text(_l10n.homeRecentlyPlayed), findsNothing);
      expect(find.text(_l10n.homeYourPlaylists), findsNothing);
    });

    testWidgets('rows update without a restart', (tester) async {
      final home = await _pump(tester);
      expect(find.text(_l10n.homeRecentlyPlayed), findsNothing);

      await home.db.historyDao.recordPlay(home.ids['Kidus']!);
      await home.db.collectionsDao.createPlaylist('Fasika');
      await tester.pumpAndSettle();

      expect(find.text(_l10n.homeRecentlyPlayed), findsOneWidget);
      expect(find.text('Kidus'), findsOneWidget);
      expect(find.text('Fasika'), findsOneWidget);
    });

    testWidgets('search button opens the Search tab', (tester) async {
      await _pump(tester);

      await tester.tap(find.byTooltip(_l10n.homeSearchTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });

  group('Home quick actions', () {
    testWidgets('Shuffle all plays the whole library', (tester) async {
      final home = await _pump(tester);

      await tester.tap(find.text(_l10n.homeShuffleAll));
      await tester.pumpAndSettle();

      final snapshot = home.handler.snapshot;
      expect(snapshot.playing, isTrue);
      expect(snapshot.shuffle, isTrue);
      expect(snapshot.queue.map((t) => t.title).toSet(), {
        'Amlak',
        'Kidus',
        'Tselot',
      });
    });

    testWidgets('Shuffle all is disabled while the first scan finds nothing', (
      tester,
    ) async {
      final scanner = GatedLibraryScanner(_files())..hold = true;
      final home = await _pump(tester, scanner: scanner, settle: false);

      expect(find.text(_l10n.libraryScanning), findsOneWidget);
      final tile = find.ancestor(
        of: find.text(_l10n.homeShuffleAll),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(tile).onTap, isNull);
      await tester.tap(find.text(_l10n.homeShuffleAll));
      await tester.pump();
      expect(home.handler.snapshot.queue, isEmpty);

      scanner.release();
      await tester.pumpAndSettle();
      expect(find.text(_l10n.libraryScanning), findsNothing);
    });

    testWidgets('Favorites opens Library on Favorites, also when asked again', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text(_l10n.libraryTabFavorites));
      await tester.pumpAndSettle();
      expect(_libraryTab(tester), LibraryTab.favorites);

      // Move to another tab in Library, then ask for Favorites again.
      await _tapText(tester, _l10n.libraryTabTracks);
      expect(_libraryTab(tester), LibraryTab.tracks);
      await _backToHome(tester);
      await tester.tap(find.text(_l10n.libraryTabFavorites));
      await tester.pumpAndSettle();

      expect(_libraryTab(tester), LibraryTab.favorites);
    });

    testWidgets('Playlists opens Library on Playlists', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(_l10n.libraryTabPlaylists));
      await tester.pumpAndSettle();

      expect(_libraryTab(tester), LibraryTab.playlists);
    });

    testWidgets('Recently added opens its auto playlist', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(_l10n.autoRecentlyAdded));
      await tester.pumpAndSettle();

      expect(find.byType(AutoPlaylistScreen), findsOneWidget);
      expect(find.text('Amlak'), findsOneWidget);
    });
  });

  group('Home Continue listening', () {
    testWidgets('resumes the paused song and hides while it plays', (
      tester,
    ) async {
      final home = await _pump(tester);
      await _pausedAt(tester, home, 'Kidus', const Duration(seconds: 83));

      expect(find.text(_l10n.homeResumeFrom('1:23')), findsOneWidget);
      await tester.tap(find.byTooltip(_l10n.homeResume));
      await tester.pumpAndSettle();

      expect(home.handler.snapshot.playing, isTrue);
      expect(home.handler.snapshot.current?.title, 'Kidus');
      expect(home.backend.loaded, hasLength(1), reason: 'no reload');
      expect(find.text(_l10n.homeContinueListening), findsNothing);
    });

    testWidgets('tapping the card resumes too', (tester) async {
      final home = await _pump(tester);
      await _pausedAt(tester, home, 'Amlak', const Duration(seconds: 5));

      await tester.tap(find.text(_l10n.homeResumeFrom('0:05')));
      await tester.pumpAndSettle();

      expect(home.handler.snapshot.playing, isTrue);
    });

    testWidgets('hidden once the song is hidden from the library', (
      tester,
    ) async {
      final home = await _pump(tester);
      await _pausedAt(tester, home, 'Kidus', const Duration(seconds: 10));
      expect(find.byType(ContinueListeningCard), findsOneWidget);
      expect(find.text(_l10n.homeContinueListening), findsOneWidget);

      await home.db.libraryDao.hideTracks([home.ids['Kidus']!]);
      await tester.pumpAndSettle();

      expect(find.text(_l10n.homeContinueListening), findsNothing);
    });
  });

  group('Home rows', () {
    testWidgets('Recently played: latest first, plays the row from a song', (
      tester,
    ) async {
      final home = await _pump(tester, plays: ['Amlak', 'Tselot', 'Kidus']);

      double left(String title) => tester.getTopLeft(find.text(title)).dx;
      expect(left('Kidus'), lessThan(left('Tselot')));
      expect(left('Tselot'), lessThan(left('Amlak')));

      await tester.tap(find.text('Tselot'));
      await tester.pumpAndSettle();

      final snapshot = home.handler.snapshot;
      expect(snapshot.current?.title, 'Tselot');
      expect(snapshot.queue.map((t) => t.title), ['Kidus', 'Tselot', 'Amlak']);
    });

    testWidgets('Recently played shows at most 10 songs', (tester) async {
      final files = [
        for (var i = 1; i <= 12; i++)
          scannedAudio(i, '/m/$i.mp3', title: 'Song $i'),
      ];
      await _pump(
        tester,
        files: files,
        plays: [for (var i = 1; i <= 12; i++) 'Song $i'],
      );

      final row = find.ancestor(
        of: find.text('Song 12'),
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Song ')),
        findsNWidgets(10),
      );
      expect(find.text('Song 2'), findsNothing);
    });

    testWidgets('Recently played See all opens the auto playlist', (
      tester,
    ) async {
      await _pump(tester, plays: ['Amlak']);

      await tester.tap(find.text(_l10n.homeSeeAll).first);
      await tester.pumpAndSettle();

      expect(find.byType(AutoPlaylistScreen), findsOneWidget);
      expect(find.text(_l10n.autoRecentlyPlayed), findsWidgets);
    });

    testWidgets('a playlist card opens the playlist; See all opens the tab', (
      tester,
    ) async {
      await _pump(
        tester,
        playlists: {
          'Timket': ['Amlak', 'Kidus'],
        },
      );
      expect(find.text(_l10n.librarySongCount(2)), findsOneWidget);

      await tester.tap(find.text('Timket'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistScreen), findsOneWidget);

      await _backToHome(tester);
      await tester.tap(find.text(_l10n.homeSeeAll));
      await tester.pumpAndSettle();
      expect(_libraryTab(tester), LibraryTab.playlists);
    });
  });

  group('Home states', () {
    testWidgets('asks for audio access like Library, then shows Home', (
      tester,
    ) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
      );
      await _pump(tester, permissions: permissions, explained: false);

      expect(find.text(_l10n.libraryAccessTitle), findsOneWidget);
      expect(find.text(_l10n.homeShuffleAll), findsNothing);

      await tester.tap(find.text(_l10n.libraryAccessAllow));
      await tester.pumpAndSettle();
      expect(permissions.requests, 1);
      expect(find.text(_l10n.homeShuffleAll), findsOneWidget);
    });

    testWidgets('empty library offers a rescan', (tester) async {
      await _pump(tester, files: const []);

      expect(find.text(_l10n.libraryEmptyTitle), findsOneWidget);
      expect(find.text(_l10n.settingsRescan), findsOneWidget);
      expect(find.text(_l10n.homeShuffleAll), findsNothing);
    });

    testWidgets('a failed first scan offers Try again', (tester) async {
      final scanner = FakeLibraryScanner(_files())
        ..error = const ScanFailure('MediaStore');
      await _pump(tester, scanner: scanner);

      expect(find.text(_l10n.libraryScanFailedTitle), findsOneWidget);
      scanner.error = null;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.homeShuffleAll), findsOneWidget);
    });

    testWidgets('fits at 1.3× on a small phone, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final home = await _pump(
          tester,
          plays: ['Amlak', 'Kidus'],
          playlists: {
            'ጥምቀት ዘመነ ሰላም የሚዘመሩ መዝሙሮች': ['Tselot'],
          },
          phoneBrightness: brightness,
        );
        await _pausedAt(tester, home, 'Tselot', const Duration(minutes: 3));
        useScreen(tester, size: const Size(320, 640), textScale: 1.3);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness top');

        await tester.scrollUntilVisible(
          find.text(_l10n.homeYourPlaylists),
          200,
          scrollable: find
              .descendant(
                of: find.byType(HomeScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness bottom');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('cards read as one label with screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, plays: ['Kidus']);

      expect(
        find.bySemanticsLabel(RegExp('Kidus.*Tewodros', dotAll: true)),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
