import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/play_history.dart';
import 'package:zema/features/library/presentation/auto_playlist_screen.dart';
import 'package:zema/features/library/presentation/song_menu.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Every file is dated 1 October 2026 (see [scannedAudio]); the tests run
/// with the clock on 20 October, so all are "recently added".
final _today = DateTime.utc(2026, 10, 20);

List<ScannedAudio> _files() => [
  scannedAudio(1, '/m/1.mp3', title: 'Amlak'),
  scannedAudio(2, '/m/2.mp3', title: 'Kidus'),
  scannedAudio(3, '/m/3.mp3', title: 'Tselot'),
];

class _App {
  _App(this.db, this.handler, this.ids);

  final ZemaDatabase db;
  final ZemaAudioHandler handler;

  /// Track IDs by title.
  final Map<String, int> ids;
}

/// Starts on Library → Playlists after recording [plays] (titles, oldest
/// first).
Future<_App> _pump(
  WidgetTester tester, {
  List<String> plays = const [],
  Brightness phoneBrightness = Brightness.dark,
}) async {
  useScreen(tester, size: const Size(360, 1000));
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
  final ids = {
    for (final t in (await tester.runAsync(db.libraryDao.allTracks))!)
      t.title: t.id,
  };
  for (final (i, title) in plays.indexed) {
    await db.historyDao.recordPlay(
      ids[title]!,
      at: _today.subtract(Duration(hours: plays.length - i)),
    );
  }
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(_l10n.libraryTabPlaylists));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_l10n.libraryTabPlaylists));
  await tester.pumpAndSettle();
  return _App(db, handler, ids);
}

Future<void> _open(WidgetTester tester, AutoPlaylistKind kind) async {
  final name = switch (kind) {
    AutoPlaylistKind.recentlyAdded => _l10n.autoRecentlyAdded,
    AutoPlaylistKind.mostPlayed => _l10n.autoMostPlayed,
    AutoPlaylistKind.recentlyPlayed => _l10n.autoRecentlyPlayed,
  };
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

/// Runs a widget test with the clock on [_today].
void _testWidgets(String name, WidgetTesterCallback body) => testWidgets(
  name,
  (tester) => withClock(Clock.fixed(_today), () => body(tester)),
);

void main() {
  group('Auto playlists', () {
    _testWidgets('show after the user playlists with their counts', (
      tester,
    ) async {
      await _pump(tester, plays: ['Kidus', 'Amlak', 'Kidus']);

      final heading = find.text(_l10n.autoPlaylistsHeading);
      expect(heading, findsOneWidget);
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(
        top(_l10n.playlistCreate),
        lessThan(top(_l10n.autoPlaylistsHeading)),
      );
      expect(
        top(_l10n.autoPlaylistsHeading),
        lessThan(top(_l10n.autoRecentlyAdded)),
      );
      expect(top(_l10n.autoRecentlyAdded), lessThan(top(_l10n.autoMostPlayed)));
      expect(
        top(_l10n.autoMostPlayed),
        lessThan(top(_l10n.autoRecentlyPlayed)),
      );
      // Recently added: all three; the played ones: two distinct songs.
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
      expect(find.text(_l10n.librarySongCount(2)), findsNWidgets(2));
    });

    _testWidgets('Most played: by plays, read-only, with Play', (tester) async {
      final app = await _pump(tester, plays: ['Amlak', 'Kidus', 'Kidus']);

      await _open(tester, AutoPlaylistKind.mostPlayed);

      expect(find.byType(AutoPlaylistScreen), findsOneWidget);
      expect(_rowTitles(tester), ['Kidus', 'Amlak']);
      // Read-only: no drag handles, no swipe, no menu of its own, no Add.
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
      expect(find.text(_l10n.playlistAddSongs), findsNothing);
      // The app bar has only Back: no rename or delete menu.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
      // Each song still has the song menu.
      expect(find.byType(SongMenuButton), findsNWidgets(2));

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(
        [for (final t in app.handler.snapshot.queue) t.title],
        ['Kidus', 'Amlak'],
      );
    });

    _testWidgets('Recently played: latest first, each song once', (
      tester,
    ) async {
      await _pump(tester, plays: ['Kidus', 'Amlak', 'Tselot', 'Kidus']);

      await _open(tester, AutoPlaylistKind.recentlyPlayed);

      expect(_rowTitles(tester), ['Kidus', 'Tselot', 'Amlak']);
    });

    _testWidgets('Recently added: newest first', (tester) async {
      await _pump(tester);

      await _open(tester, AutoPlaylistKind.recentlyAdded);

      // Same date for all: the one stored last first.
      expect(_rowTitles(tester), ['Tselot', 'Kidus', 'Amlak']);
    });

    _testWidgets('a song hidden from its menu leaves the auto playlist', (
      tester,
    ) async {
      await _pump(tester, plays: ['Amlak', 'Kidus']);
      await _open(tester, AutoPlaylistKind.recentlyPlayed);

      await tester.tap(find.byTooltip(_l10n.songMenu('Kidus')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.songHide));
      await tester.pumpAndSettle();

      expect(_rowTitles(tester), ['Amlak']);
    });

    _testWidgets('empty auto playlists explain what fills them', (
      tester,
    ) async {
      await _pump(tester);

      await _open(tester, AutoPlaylistKind.mostPlayed);
      expect(find.text(_l10n.autoPlayedEmptyTitle), findsOneWidget);
      expect(find.text(_l10n.autoMostPlayedEmptyMessage), findsOneWidget);
      expect(find.text(_l10n.actionPlay), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await _open(tester, AutoPlaylistKind.recentlyPlayed);
      expect(find.text(_l10n.autoRecentlyPlayedEmptyMessage), findsOneWidget);
    });

    _testWidgets('nothing added in 30 days: Recently added is empty', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 12, 1)), () async {
        await _pump(tester);
        await _open(tester, AutoPlaylistKind.recentlyAdded);
      });

      expect(find.text(_l10n.autoRecentlyAddedEmptyTitle), findsOneWidget);
    });

    _testWidgets('a malformed link shows C07', (tester) async {
      await _pump(tester);

      tester
          .element(find.byType(Scaffold).first)
          .go('${AppRoutes.library}/${AppRoutes.autoPlaylistPath}?kind=x');
      await tester.pumpAndSettle();

      expect(find.text(_l10n.errorNotFoundTitle), findsOneWidget);
    });

    _testWidgets('fit at 1.3× on a small phone, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          plays: ['Amlak', 'Kidus'],
          phoneBrightness: brightness,
        );
        useScreen(tester, size: const Size(320, 640), textScale: 1.3);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$brightness tab');

        await tester.ensureVisible(find.text(_l10n.autoRecentlyPlayed));
        await tester.pumpAndSettle();
        await _open(tester, AutoPlaylistKind.recentlyPlayed);
        expect(tester.takeException(), isNull, reason: '$brightness page');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
