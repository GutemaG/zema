import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/add_to_playlist_sheet.dart';
import 'package:zema/features/library/presentation/album_screen.dart';
import 'package:zema/features/library/presentation/artist_screen.dart';
import 'package:zema/features/library/presentation/song_menu.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/player/presentation/mini_player.dart';
import 'package:zema/features/player/presentation/now_playing_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(1, '/m/1.mp3', title: 'Amlak', artist: 'Zerfe', album: 'Vol 1'),
  scannedAudio(2, '/m/2.mp3', title: 'Kidus', artist: 'Mahlet'),
  scannedAudio(3, '/m/3.mp3', title: 'Tselot', artist: 'Zerfe'),
];

class _App {
  _App(this.db, this.handler, this.share);

  final ZemaDatabase db;
  final ZemaAudioHandler handler;
  final FakeAudioShareService share;

  List<String> queue() => [for (final t in handler.snapshot.queue) t.title];
}

/// Opens Library → Tracks.
Future<_App> _pump(
  WidgetTester tester, {
  Brightness phoneBrightness = Brightness.dark,
}) async {
  useScreen(tester, size: const Size(360, 900));
  final app = _App(
    memoryDatabase(),
    fakeAudioHandler(),
    FakeAudioShareService(),
  );
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner(_files()),
    database: app.db,
    shareService: app.share,
    audioHandler: app.handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  return app;
}

Future<void> _openMenu(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip(_l10n.songMenu(title)).first);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String title, String item) async {
  await _openMenu(tester, title);
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

/// Opens Now Playing from the mini player showing [title].
Future<void> _openPlayer(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(of: find.byType(MiniPlayer), matching: find.text(title)),
  );
  await tester.pumpAndSettle();
}

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

void main() {
  group('Song menu', () {
    testWidgets('offers every action but edit info', (tester) async {
      await _pump(tester);

      await _openMenu(tester, 'Amlak');

      expect(find.byType(SongMenu), findsOneWidget);
      for (final item in [
        _l10n.songPlayNext,
        _l10n.songAddToQueue,
        _l10n.songAddToPlaylist,
        _l10n.songFavorite,
        _l10n.songMatchLyrics,
        _l10n.songGoToAlbum,
        _l10n.songGoToArtist,
        _l10n.songHide,
        _l10n.songShare,
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      // Not linked, so nothing to unlink or change.
      expect(find.text(_l10n.songUnlinkLyrics), findsNothing);
      expect(find.text(_l10n.songChangeLyrics), findsNothing);
      expect(find.textContaining('dit'), findsNothing);
    });

    testWidgets('Play next and Add to queue, with a snackbar', (tester) async {
      final app = await _pump(tester);
      await tester.tap(find.text('Amlak'));
      await tester.pumpAndSettle();
      expect(app.queue(), ['Amlak', 'Kidus', 'Tselot']);

      await _choose(tester, 'Tselot', _l10n.songPlayNext);
      expect(app.queue(), ['Amlak', 'Tselot', 'Kidus', 'Tselot']);
      expect(find.text(_l10n.songPlayingNext('Tselot')), findsOneWidget);

      await _choose(tester, 'Amlak', _l10n.songAddToQueue);
      expect(app.queue(), ['Amlak', 'Tselot', 'Kidus', 'Tselot', 'Amlak']);
      expect(find.text(_l10n.songAddedToQueue('Amlak')), findsOneWidget);
      expect(app.handler.snapshot.current?.title, 'Amlak');
    });

    testWidgets('Add to queue with nothing playing shows the mini player', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _choose(tester, 'Kidus', _l10n.songAddToQueue);

      expect(app.queue(), ['Kidus']);
      expect(app.handler.snapshot.playing, isFalse);
      expect(find.byTooltip(_l10n.playerPlay), findsOneWidget);
    });

    testWidgets('favorite updates the menu, the Favorites tab and S08', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _choose(tester, 'Kidus', _l10n.songFavorite);
      expect(find.text(_l10n.songFavorited('Kidus')), findsOneWidget);
      // Let the snackbar time out so it doesn't cover Now Playing's buttons.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _openMenu(tester, 'Kidus');
      expect(find.text(_l10n.songUnfavorite), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(_l10n.libraryTabFavorites));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.libraryTabFavorites));
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Kidus']);

      // Now Playing's heart shows it, and unfavoriting there updates the tab.
      await tester.tap(find.text('Kidus'));
      await tester.pumpAndSettle();
      await _openPlayer(tester, 'Kidus');
      expect(find.byType(NowPlayingScreen), findsOneWidget);
      await tester.tap(find.byTooltip(_l10n.songUnfavorite));
      await tester.pumpAndSettle();
      expect(find.byTooltip(_l10n.songFavorite), findsOneWidget);
      await tester.tap(find.byTooltip(_l10n.playerClose));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.favoritesEmptyTitle), findsOneWidget);
      expect(app.queue(), ['Kidus']);
    });

    testWidgets('Hide removes the song everywhere; Undo brings it back', (
      tester,
    ) async {
      await _pump(tester);

      await _choose(tester, 'Kidus', _l10n.songHide);
      expect(_rowTitles(tester), ['Amlak', 'Tselot']);
      expect(find.text(_l10n.songHidden('Kidus')), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Amlak', 'Kidus', 'Tselot']);
    });

    testWidgets('hiding the playing song keeps it playing', (tester) async {
      final app = await _pump(tester);
      await tester.tap(find.text('Kidus'));
      await tester.pumpAndSettle();

      await _choose(tester, 'Kidus', _l10n.songHide);

      expect(_rowTitles(tester), ['Amlak', 'Tselot']);
      expect(app.handler.snapshot.current?.title, 'Kidus');
      expect(app.handler.snapshot.playing, isTrue);
      expect(app.queue(), ['Amlak', 'Kidus', 'Tselot']);
    });

    testWidgets('Share hands the song to the share sheet', (tester) async {
      final app = await _pump(tester);

      await _choose(tester, 'Amlak', _l10n.songShare);
      expect([for (final t in app.share.shared) t.title], ['Amlak']);

      app.share.fails = true;
      await _choose(tester, 'Amlak', _l10n.songShare);
      expect(find.text(_l10n.songShareFailed), findsOneWidget);
    });

    testWidgets('Go to album and Go to artist open S12a and S13a', (
      tester,
    ) async {
      await _pump(tester);

      await _choose(tester, 'Amlak', _l10n.songGoToAlbum);
      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(find.text('Vol 1'), findsOneWidget);

      await _choose(tester, 'Amlak', _l10n.songGoToArtist);
      expect(find.byType(ArtistScreen), findsOneWidget);
      expect(find.text('Zerfe'), findsWidgets);
    });

    testWidgets('from Now Playing, Go to album closes the player', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('Amlak'));
      await tester.pumpAndSettle();
      await _openPlayer(tester, 'Amlak');

      await _choose(tester, 'Amlak', _l10n.songGoToAlbum);

      expect(find.byType(NowPlayingScreen), findsNothing);
      expect(find.byType(AlbumScreen), findsOneWidget);
    });
  });

  group('Add to playlist sheet', () {
    testWidgets('checkmarks show membership; a tap adds or removes', (
      tester,
    ) async {
      final app = await _pump(tester);
      final ids = {
        for (final t in (await tester.runAsync(app.db.libraryDao.allTracks))!)
          t.title: t.id,
      };
      final kidase = await app.db.collectionsDao.createPlaylist('Kidase');
      await app.db.collectionsDao.createPlaylist('Timket');
      await app.db.collectionsDao.addToPlaylist(kidase, [ids['Amlak']!]);
      await tester.pumpAndSettle();

      await _choose(tester, 'Amlak', _l10n.songAddToPlaylist);
      expect(find.byType(AddToPlaylistSheet), findsOneWidget);
      expect(find.text(_l10n.playlistNew), findsOneWidget);
      bool checked(String name) => tester
          .widget<CheckboxListTile>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .value!;
      expect(checked('Kidase'), isTrue);
      expect(checked('Timket'), isFalse);

      await tester.tap(find.text('Timket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kidase'));
      await tester.pumpAndSettle();

      expect(find.byType(AddToPlaylistSheet), findsOneWidget);
      expect(checked('Kidase'), isFalse);
      expect(checked('Timket'), isTrue);
    });

    testWidgets('New playlist creates it with the song in it', (tester) async {
      final app = await _pump(tester);

      await _choose(tester, 'Kidus', _l10n.songAddToPlaylist);
      await tester.tap(find.text(_l10n.playlistNew));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Timket',
      );
      await tester.pump();
      await tester.tap(find.text(_l10n.actionCreate));
      await tester.pumpAndSettle();

      expect(find.byType(AddToPlaylistSheet), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.ancestor(
                of: find.text('Timket'),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isTrue,
      );
      final playlists = await tester.runAsync(
        () => app.db.collectionsDao.watchPlaylists().first,
      );
      expect(playlists!.single.trackIds, hasLength(1));
    });
  });

  testWidgets('menu and sheet fit at 1.3× on a small phone, light and dark', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final app = await _pump(tester, phoneBrightness: brightness);
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      await app.db.collectionsDao.createPlaylist('ቅዳሴ የሰንበት መዝሙሮች ለጥምቀት በዓል');
      await tester.pumpAndSettle();

      await _openMenu(tester, 'Amlak');
      expect(tester.takeException(), isNull, reason: '$brightness menu');
      await tester.tap(find.text(_l10n.songAddToPlaylist));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness sheet');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
