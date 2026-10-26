import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(1, '/m/1.mp3', title: 'Amlak', artist: 'Zerfe'),
  scannedAudio(2, '/m/2.mp3', title: 'Kidus', artist: 'Mahlet'),
  scannedAudio(3, '/m/3.mp3', title: 'ሰላም ለኪ', artist: 'ዘማሪት'),
  scannedAudio(4, '/m/4.mp3', title: 'Tselot', artist: 'Zerfe'),
];

/// The tracks' IDs by title.
Future<Map<String, int>> _ids(ZemaDatabase db) async => {
  for (final t in await db.libraryDao.allTracks()) t.title: t.id,
};

/// Opens Favorites with [favorites] favorited, oldest first.
Future<(ZemaDatabase, ZemaAudioHandler)> _pump(
  WidgetTester tester, {
  List<String> favorites = const [],
  Brightness phoneBrightness = Brightness.dark,
}) async {
  final db = memoryDatabase();
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner(_files()),
    database: db,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  final ids = await _ids(db);
  for (final (i, title) in favorites.indexed) {
    await db.collectionsDao.addFavorite(
      ids[title]!,
      at: DateTime.utc(2026, 1, 1 + i),
    );
  }
  await tester.ensureVisible(find.text(_l10n.libraryTabFavorites));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l10n.libraryTabFavorites));
  await tester.pumpAndSettle();
  return (db, handler);
}

List<String> _titles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

void main() {
  group('Favorites', () {
    testWidgets('no favorites shows C07 explaining how to add one', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(_l10n.favoritesEmptyTitle), findsOneWidget);
      expect(find.text(_l10n.favoritesEmptyMessage), findsOneWidget);
    });

    testWidgets('lists favorites newest first, with search and Play', (
      tester,
    ) async {
      final (_, handler) = await _pump(
        tester,
        favorites: ['Kidus', 'Amlak', 'ሰላም ለኪ'],
      );

      expect(_titles(tester), ['ሰላም ለኪ', 'Amlak', 'Kidus']);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(
        [for (final t in handler.snapshot.queue) t.title],
        ['ሰላም ለኪ', 'Amlak', 'Kidus'],
      );

      await tester.enterText(find.byType(TextField), 'zer');
      await tester.pumpAndSettle();
      expect(_titles(tester), ['Amlak']);
    });

    testWidgets('swipe removes a song; Undo puts it back in place', (
      tester,
    ) async {
      await _pump(tester, favorites: ['Kidus', 'Amlak', 'Tselot']);

      await tester.drag(find.text('Amlak'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(_titles(tester), ['Tselot', 'Kidus']);
      expect(find.text(_l10n.songUnfavorited('Amlak')), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();
      expect(_titles(tester), ['Tselot', 'Amlak', 'Kidus']);
    });

    testWidgets('screen readers can remove a song too', (tester) async {
      await _pump(tester, favorites: ['Kidus', 'Amlak']);

      final remove = tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('Amlak'),
              matching: find.byType(Semantics),
            ),
          )
          .map((s) => s.properties.customSemanticsActions)
          .nonNulls
          .expand((actions) => actions.entries)
          .singleWhere((a) => a.key.label == _l10n.songUnfavorite);
      remove.value();
      await tester.pumpAndSettle();

      expect(_titles(tester), ['Kidus']);
    });

    testWidgets('a hidden favorite is not listed but is kept', (tester) async {
      final (db, _) = await _pump(tester, favorites: ['Kidus', 'Amlak']);

      final ids = await _ids(db);
      await db.libraryDao.hideTrack(ids['Amlak']!);
      await tester.pumpAndSettle();
      expect(_titles(tester), ['Kidus']);

      await db.libraryDao.unhideTrack(ids['Amlak']!);
      await tester.pumpAndSettle();
      expect(_titles(tester), ['Amlak', 'Kidus']);
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          favorites: ['Kidus', 'ሰላም ለኪ'],
          phoneBrightness: brightness,
        );
        expect(tester.takeException(), isNull, reason: '$brightness');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
