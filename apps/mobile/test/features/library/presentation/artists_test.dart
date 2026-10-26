import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/album_screen.dart';
import 'package:zema/features/library/presentation/artist_screen.dart';
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
  scannedAudio(1, '/m/1.mp3', title: 'Zion', artist: 'Zerfe', album: 'Old'),
  scannedAudio(2, '/m/2.mp3', title: 'Amen', artist: 'Zerfe', album: 'New'),
  scannedAudio(3, '/m/3.mp3', title: 'ሰላም', artist: 'ዘማሪት'),
  scannedAudio(4, '/m/4.mp3', title: 'Untagged'),
];

Future<ZemaAudioHandler> _pump(
  WidgetTester tester, {
  List<ScannedAudio>? files,
  String? location,
  Brightness phoneBrightness = Brightness.dark,
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: location ?? AppRoutes.library,
    libraryScanner: FakeLibraryScanner(files ?? _files()),
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  if (location == null) {
    // The tab bar scrolls: on narrow screens the tab may start off-screen.
    await tester.ensureVisible(find.text(_l10n.libraryTabArtists));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.libraryTabArtists));
    await tester.pumpAndSettle();
  }
  return handler;
}

void main() {
  group('Artists', () {
    testWidgets('lists artists with song counts, unknown last', (tester) async {
      await _pump(tester);

      expect(find.text(_l10n.artistCount(3)), findsOneWidget);
      final zerfe = tester.getTopLeft(find.text('Zerfe')).dy;
      final ethiopic = tester.getTopLeft(find.text('ዘማሪት')).dy;
      final unknown = tester.getTopLeft(find.text(_l10n.unknownArtist)).dy;
      expect(zerfe, lessThan(ethiopic));
      expect(ethiopic, lessThan(unknown));
      expect(find.text(_l10n.librarySongCount(2)), findsOneWidget);
    });

    testWidgets('an artist shows their albums and songs; Play plays them', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 1000));
      final handler = await _pump(tester);

      await tester.tap(find.text('Zerfe'));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistScreen), findsOneWidget);
      expect(find.text(_l10n.artistAlbums), findsOneWidget);
      expect(find.text(_l10n.artistSongs), findsOneWidget);
      expect(find.byType(AlbumTile), findsNWidgets(2));
      expect(
        [
          for (final r in tester.widgetList<TrackRow>(find.byType(TrackRow)))
            r.track.title,
        ],
        ['Amen', 'Zion'],
      );

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(
        [for (final t in handler.snapshot.queue) t.title],
        ['Amen', 'Zion'],
      );
    });

    testWidgets('an album cover opens the album', (tester) async {
      useScreen(tester, size: const Size(360, 1000));
      await _pump(tester);
      await tester.tap(find.text('Zerfe'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AlbumTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('"Unknown artist" holds songs without an artist', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 1000));
      await _pump(tester);

      await tester.tap(find.text(_l10n.unknownArtist));
      await tester.pumpAndSettle();

      expect(find.byType(ArtistScreen), findsOneWidget);
      expect(find.widgetWithText(TrackRow, 'Untagged'), findsOneWidget);
    });

    testWidgets('an artist no longer in the library shows C07', (tester) async {
      await _pump(tester, location: AppRoutes.artist('Nobody'));

      expect(find.text(_l10n.artistGoneTitle), findsOneWidget);
    });

    testWidgets('an empty library shows C07', (tester) async {
      await _pump(tester, files: const []);

      expect(find.text(_l10n.artistsEmptyTitle), findsOneWidget);
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pump(tester, phoneBrightness: brightness);
        expect(tester.takeException(), isNull, reason: '$brightness list');
        await tester.tap(find.text('Zerfe'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness artist');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
