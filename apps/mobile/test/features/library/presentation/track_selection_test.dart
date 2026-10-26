import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/widgets/library_search_field.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/library/presentation/widgets/track_selection_bar.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(1, '/m/1.mp3', title: 'Amlak'),
  scannedAudio(2, '/m/2.mp3', title: 'Kidus'),
  scannedAudio(3, '/m/3.mp3', title: 'Tselot'),
  scannedAudio(4, '/m/4.mp3', title: 'Zema'),
];

class _App {
  _App(this.db, this.handler);

  final ZemaDatabase db;
  final ZemaAudioHandler handler;

  List<String> queue() => [for (final t in handler.snapshot.queue) t.title];
}

/// Opens Library → Tracks.
Future<_App> _pump(
  WidgetTester tester, {
  Brightness phoneBrightness = Brightness.dark,
}) async {
  useScreen(tester, size: const Size(360, 900));
  final app = _App(memoryDatabase(), fakeAudioHandler());
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner(_files()),
    database: app.db,
    audioHandler: app.handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  return app;
}

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(TrackRow));

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

List<String> _selectedTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    if (row.selected) row.track.title,
];

Future<void> _longPress(WidgetTester tester, String title) async {
  await tester.longPress(_row(title));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String title) async {
  await tester.tap(_row(title));
  await tester.pumpAndSettle();
}

Future<void> _action(WidgetTester tester, String tooltip) async {
  await tester.tap(
    find.descendant(
      of: find.byType(TrackSelectionBar),
      matching: find.byTooltip(tooltip),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Tracks multi-select', () {
    testWidgets('a long-press starts selection with that song and a count', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _longPress(tester, 'Kidus');

      expect(find.byType(TrackSelectionBar), findsOneWidget);
      expect(find.text(_l10n.selectionCount(1)), findsOneWidget);
      expect(_selectedTitles(tester), ['Kidus']);
      // The search field and Play / Shuffle make way for the bar.
      expect(find.byType(LibrarySearchField), findsNothing);
      expect(find.byType(Checkbox), findsNWidgets(4));
      // Nothing started playing.
      expect(app.handler.snapshot.hasTrack, isFalse);
    });

    testWidgets('taps toggle songs; deselecting the last one ends it', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Kidus');

      await _tap(tester, 'Zema');
      await _tap(tester, 'Amlak');
      expect(_selectedTitles(tester), ['Amlak', 'Kidus', 'Zema']);
      expect(find.text(_l10n.selectionCount(3)), findsOneWidget);

      await _tap(tester, 'Kidus');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(_selectedTitles(tester), ['Zema']);

      await _tap(tester, 'Zema');
      expect(find.byType(TrackSelectionBar), findsNothing);
      expect(find.byType(LibrarySearchField), findsOneWidget);
      expect(app.handler.snapshot.hasTrack, isFalse);
    });

    testWidgets('Select all selects the list as filtered by the search', (
      tester,
    ) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Amlak', 'Zema']);

      await _longPress(tester, 'Amlak');
      await tester.tap(find.text(_l10n.selectionSelectAll));
      await tester.pumpAndSettle();

      // Two of the four songs: the ones the search shows.
      expect(find.text(_l10n.selectionCount(2)), findsOneWidget);
      expect(_selectedTitles(tester), ['Amlak', 'Zema']);
    });

    testWidgets('Select all with no search selects every song', (tester) async {
      await _pump(tester);
      await _longPress(tester, 'Kidus');

      await tester.tap(find.text(_l10n.selectionSelectAll));
      await tester.pumpAndSettle();

      expect(_selectedTitles(tester), ['Amlak', 'Kidus', 'Tselot', 'Zema']);
    });

    testWidgets('back ends selection without changes', (tester) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Kidus');
      await _tap(tester, 'Tselot');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TrackSelectionBar), findsNothing);
      // Still on Library → Tracks, with every song.
      expect(_rowTitles(tester), ['Amlak', 'Kidus', 'Tselot', 'Zema']);
      expect(app.handler.snapshot.hasTrack, isFalse);
      final hidden = await tester.runAsync(
        () => app.db.libraryDao.watchHiddenTracks().first,
      );
      expect(hidden, isEmpty);
    });

    testWidgets('the close button ends selection', (tester) async {
      await _pump(tester);
      await _longPress(tester, 'Kidus');

      await tester.tap(find.byTooltip(_l10n.selectionClose));
      await tester.pumpAndSettle();

      expect(find.byType(TrackSelectionBar), findsNothing);
    });

    testWidgets('Add to queue adds the songs in list order and ends it', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Zema');
      await _tap(tester, 'Amlak');

      await _action(tester, _l10n.songAddToQueue);

      expect(app.queue(), ['Amlak', 'Zema']);
      // With nothing playing, the songs are loaded paused.
      expect(app.handler.snapshot.playing, isFalse);
      expect(find.byType(TrackSelectionBar), findsNothing);
      expect(find.text(_l10n.selectionAddedToQueue(2)), findsOneWidget);
    });

    testWidgets('Favorite favorites all; then the button unfavorites them', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Kidus');
      await _tap(tester, 'Tselot');

      await _action(tester, _l10n.songFavorite);
      expect(find.text(_l10n.selectionFavorited(2)), findsOneWidget);
      var favorites = await tester.runAsync(
        () => app.db.collectionsDao.watchFavorites().first,
      );
      expect(favorites, hasLength(2));

      await _longPress(tester, 'Kidus');
      await _tap(tester, 'Tselot');
      // Every selected song is a favorite: the action removes them.
      await _action(tester, _l10n.songUnfavorite);
      expect(find.text(_l10n.selectionUnfavorited(2)), findsOneWidget);
      favorites = await tester.runAsync(
        () => app.db.collectionsDao.watchFavorites().first,
      );
      expect(favorites, isEmpty);
    });

    testWidgets('a mix of favorites and others offers Favorite', (
      tester,
    ) async {
      await _pump(tester);
      await _longPress(tester, 'Kidus');
      await _action(tester, _l10n.songFavorite);

      await _longPress(tester, 'Kidus');
      await _tap(tester, 'Amlak');

      expect(find.byTooltip(_l10n.songFavorite), findsOneWidget);
      expect(find.byTooltip(_l10n.songUnfavorite), findsNothing);
    });

    testWidgets('Hide hides them all; Undo brings them back', (tester) async {
      await _pump(tester);
      await _longPress(tester, 'Kidus');
      await _tap(tester, 'Zema');

      await _action(tester, _l10n.songHide);

      expect(_rowTitles(tester), ['Amlak', 'Tselot']);
      expect(find.byType(TrackSelectionBar), findsNothing);
      expect(find.text(_l10n.selectionHidden(2)), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Amlak', 'Kidus', 'Tselot', 'Zema']);
    });

    testWidgets('Add to playlist adds the songs to the one picked', (
      tester,
    ) async {
      final app = await _pump(tester);
      final id = await tester.runAsync(
        () => app.db.collectionsDao.createPlaylist('Timket'),
      );
      await tester.runAsync(
        () => app.db.collectionsDao.addToPlaylist(id!, [1]),
      );
      await tester.pumpAndSettle();
      await _longPress(tester, 'Amlak');
      await _tap(tester, 'Tselot');

      await _action(tester, _l10n.songAddToPlaylist);
      expect(find.text(_l10n.selectionAddToPlaylistTitle(2)), findsOneWidget);
      await tester.tap(find.text('Timket'));
      await tester.pumpAndSettle();

      // Amlak was already there, so only Tselot is new.
      expect(
        find.text(_l10n.selectionAddedToPlaylist(1, 'Timket')),
        findsOneWidget,
      );
      expect(find.byType(TrackSelectionBar), findsNothing);
      final playlists = await tester.runAsync(
        () => app.db.collectionsDao.watchPlaylists().first,
      );
      expect(playlists!.single.trackIds, hasLength(2));
    });

    testWidgets('Add to playlist → New playlist creates it with the songs', (
      tester,
    ) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Amlak');
      await _tap(tester, 'Kidus');

      await _action(tester, _l10n.songAddToPlaylist);
      await tester.tap(find.text(_l10n.playlistNew));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField).first,
        ),
        'Kidase',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.actionCreate));
      await tester.pumpAndSettle();

      expect(
        find.text(_l10n.selectionAddedToPlaylist(2, 'Kidase')),
        findsOneWidget,
      );
      final playlists = await tester.runAsync(
        () => app.db.collectionsDao.watchPlaylists().first,
      );
      expect(playlists!.single.name, 'Kidase');
      expect(playlists.single.trackIds, hasLength(2));
    });

    testWidgets('dismissing the playlist sheet keeps the selection', (
      tester,
    ) async {
      await _pump(tester);
      await _longPress(tester, 'Amlak');

      await _action(tester, _l10n.songAddToPlaylist);
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();

      expect(find.byType(TrackSelectionBar), findsOneWidget);
      expect(_selectedTitles(tester), ['Amlak']);
    });

    testWidgets('a song hidden elsewhere leaves the selection', (tester) async {
      final app = await _pump(tester);
      await _longPress(tester, 'Amlak');
      await _tap(tester, 'Kidus');

      await tester.runAsync(() => app.db.libraryDao.hideTrack(1));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.selectionCount(1)), findsOneWidget);
      expect(_selectedTitles(tester), ['Kidus']);
    });

    testWidgets('the bar fits at 1.3× on a small phone, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await _pump(tester, phoneBrightness: brightness);
        useScreen(tester, size: const Size(320, 640), textScale: 1.3);
        await tester.pumpAndSettle();

        await _longPress(tester, 'Amlak');
        await tester.tap(find.text(_l10n.selectionSelectAll));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness bar');

        await _action(tester, _l10n.songAddToPlaylist);
        expect(tester.takeException(), isNull, reason: '$brightness sheet');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
