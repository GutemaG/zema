import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/add_songs_screen.dart';
import 'package:zema/features/library/presentation/playlist_screen.dart';
import 'package:zema/features/library/presentation/widgets/playlist_collage.dart';
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
  scannedAudio(5, '/m/5.mp3', title: 'Wudase', artist: 'Mahlet'),
];

class _App {
  _App(this.db, this.handler, this.ids);

  final ZemaDatabase db;
  final ZemaAudioHandler handler;

  /// Track IDs by title.
  final Map<String, int> ids;

  /// The stored song titles of playlist [id], hidden ones included.
  Future<List<String>> stored(WidgetTester tester, int id) async {
    final playlists = await tester.runAsync(
      () => db.collectionsDao.watchPlaylists().first,
    );
    final byId = {for (final e in ids.entries) e.value: e.key};
    return [
      for (final trackId in playlists!.singleWhere((p) => p.id == id).trackIds)
        byId[trackId]!,
    ];
  }
}

/// Starts the app at [location] (default: Library, Playlists tab) with
/// [playlists] (name → song titles) created first.
Future<(_App, Map<String, int>)> _pump(
  WidgetTester tester, {
  Map<String, List<String>> playlists = const {},
  String? Function(Map<String, int> playlistIds)? location,
  Brightness phoneBrightness = Brightness.dark,
  bool tall = true,
}) async {
  // Tall enough that every row of the test playlists is built.
  if (tall) useScreen(tester, size: const Size(360, 1000));
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
  final playlistIds = <String, int>{};
  for (final MapEntry(key: name, value: titles) in playlists.entries) {
    final id = await db.collectionsDao.createPlaylist(name);
    await db.collectionsDao.addToPlaylist(id, [
      for (final t in titles) ids[t]!,
    ]);
    playlistIds[name] = id;
  }
  await tester.pumpAndSettle();
  final path = location?.call(playlistIds);
  if (path != null) {
    tester.element(find.byType(Scaffold).first).go(path);
  } else {
    await tester.ensureVisible(find.text(_l10n.libraryTabPlaylists));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.libraryTabPlaylists));
  }
  await tester.pumpAndSettle();
  return (_App(db, handler, ids), playlistIds);
}

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

TextButton _button(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
);

String _playlistRoute(int id) => AppRoutes.playlist(id);

void main() {
  group('Playlists tab and dialog', () {
    testWidgets('with no playlists the Create card comes straight before '
        'the auto playlists', (tester) async {
      await _pump(tester);

      expect(find.text(_l10n.playlistCreate), findsOneWidget);
      expect(find.text(_l10n.playlistCreateHint), findsOneWidget);
      expect(find.byType(PlaylistCollage), findsNothing);
      expect(find.text(_l10n.autoPlaylistsHeading), findsOneWidget);
    });

    testWidgets('lists playlists by name with their song count', (
      tester,
    ) async {
      await _pump(
        tester,
        playlists: {
          'Timket': ['Amlak'],
          'kidase': ['Kidus', 'Tselot'],
        },
      );

      final kidase = tester.getTopLeft(find.text('kidase')).dy;
      final timket = tester.getTopLeft(find.text('Timket')).dy;
      expect(kidase, lessThan(timket));
      expect(find.text(_l10n.librarySongCount(2)), findsOneWidget);
      expect(find.text(_l10n.librarySongCount(1)), findsOneWidget);
    });

    testWidgets('the name is required and unique; Create opens it', (
      tester,
    ) async {
      await _pump(
        tester,
        playlists: {
          'Kidase': ['Amlak'],
        },
      );

      await tester.tap(find.text(_l10n.playlistCreate));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.playlistNew), findsOneWidget);
      expect(_button(tester, _l10n.actionCreate).onPressed, isNull);

      final name = find.byType(TextField).first;
      await tester.enterText(name, '   ');
      await tester.pump();
      expect(find.text(_l10n.playlistNameRequired), findsOneWidget);
      expect(_button(tester, _l10n.actionCreate).onPressed, isNull);

      await tester.enterText(name, ' KIDASE ');
      await tester.pump();
      expect(find.text(_l10n.playlistNameTaken), findsOneWidget);
      expect(_button(tester, _l10n.actionCreate).onPressed, isNull);

      await tester.enterText(name, 'Timket');
      await tester.enterText(find.byType(TextField).last, 'For January');
      await tester.pump();
      expect(find.text(_l10n.playlistNameTaken), findsNothing);
      await tester.tap(find.text(_l10n.actionCreate));
      await tester.pumpAndSettle();

      expect(find.byType(PlaylistScreen), findsOneWidget);
      expect(find.text('Timket'), findsOneWidget);
      expect(find.text('For January'), findsOneWidget);
      expect(find.text(_l10n.playlistEmptyTitle), findsOneWidget);
    });

    testWidgets('Cancel creates nothing', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(_l10n.playlistCreate));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Timket');
      await tester.tap(find.text(_l10n.actionCancel));
      await tester.pumpAndSettle();

      expect(find.text('Timket'), findsNothing);
    });
  });

  group('Playlist page', () {
    testWidgets('shows name, count, duration; Play plays in order', (
      tester,
    ) async {
      final (app, _) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Tselot', 'Amlak', 'Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      expect(find.text('Kidase'), findsOneWidget);
      expect(
        find.text('${_l10n.librarySongCount(3)} · ${_l10n.durationMinutes(3)}'),
        findsOneWidget,
      );
      expect(_rowTitles(tester), ['Tselot', 'Amlak', 'Kidus']);

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(
        [for (final t in app.handler.snapshot.queue) t.title],
        ['Tselot', 'Amlak', 'Kidus'],
      );
    });

    testWidgets('dragging a song saves the order', (tester) async {
      final (app, ids) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Tselot', 'Amlak', 'Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      final handle = find.byTooltip(_l10n.queueReorder).at(2);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(0, -TrackRow.height / 10));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_rowTitles(tester), ['Kidus', 'Tselot', 'Amlak']);
      expect(await app.stored(tester, ids['Kidase']!), [
        'Kidus',
        'Tselot',
        'Amlak',
      ]);
    });

    testWidgets('a hidden song keeps its slot when others move', (
      tester,
    ) async {
      final (app, ids) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Tselot', 'Amlak', 'Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );
      await app.db.libraryDao.hideTrack(app.ids['Amlak']!);
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Tselot', 'Kidus']);

      final handle = find.byTooltip(_l10n.queueReorder).at(1);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -TrackRow.height / 10));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_rowTitles(tester), ['Kidus', 'Tselot']);
      expect(await app.stored(tester, ids['Kidase']!), [
        'Kidus',
        'Amlak',
        'Tselot',
      ]);
    });

    testWidgets('swipe removes a song; Undo puts it back in place', (
      tester,
    ) async {
      final (app, ids) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Tselot', 'Amlak', 'Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      await tester.drag(find.text('Amlak'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Tselot', 'Kidus']);
      expect(find.text(_l10n.playlistRemoved('Amlak')), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();
      expect(_rowTitles(tester), ['Tselot', 'Amlak', 'Kidus']);
      expect(await app.stored(tester, ids['Kidase']!), [
        'Tselot',
        'Amlak',
        'Kidus',
      ]);
    });

    testWidgets('Rename opens S16 with the name filled in', (tester) async {
      await _pump(
        tester,
        playlists: {
          'Kidase': ['Amlak'],
          'Timket': ['Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      await tester.tap(find.byTooltip(_l10n.playlistMenu('Kidase')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.playlistRename));
      await tester.pumpAndSettle();
      final name = find.byType(TextField).first;
      expect(tester.widget<TextField>(name).controller!.text, 'Kidase');
      // Its own name is fine; another playlist's isn't.
      expect(_button(tester, _l10n.actionSave).onPressed, isNotNull);
      await tester.enterText(name, 'timket');
      await tester.pump();
      expect(find.text(_l10n.playlistNameTaken), findsOneWidget);

      await tester.enterText(name, 'Sunday Kidase');
      await tester.pump();
      await tester.tap(find.text(_l10n.actionSave));
      await tester.pumpAndSettle();

      expect(find.text('Sunday Kidase'), findsOneWidget);
    });

    testWidgets('Delete asks first, then deletes and goes back', (
      tester,
    ) async {
      final (app, _) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Amlak'],
        },
      );
      await tester.tap(find.text('Kidase'));
      await tester.pumpAndSettle();

      Future<void> chooseDelete() async {
        await tester.tap(find.byTooltip(_l10n.playlistMenu('Kidase')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_l10n.playlistDelete));
        await tester.pumpAndSettle();
        expect(find.text(_l10n.playlistDeleteMessage('Kidase')), findsOne);
      }

      await chooseDelete();
      await tester.tap(find.text(_l10n.actionCancel));
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistScreen), findsOneWidget);

      await chooseDelete();
      await tester.tap(find.text(_l10n.actionDelete));
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistScreen), findsNothing);
      expect(find.text('Kidase'), findsNothing);
      expect(find.text(_l10n.playlistCreate), findsOneWidget);
      final left = await tester.runAsync(
        () => app.db.collectionsDao.watchPlaylists().first,
      );
      expect(left, isEmpty);
    });

    testWidgets('an unknown playlist shows C07', (tester) async {
      await _pump(tester, location: (_) => _playlistRoute(999));

      expect(find.text(_l10n.playlistGoneTitle), findsOneWidget);
    });
  });

  group('Add songs picker', () {
    testWidgets('marks songs already in, keeps picks across searches, '
        'adds in pick order', (tester) async {
      final (app, ids) = await _pump(
        tester,
        playlists: {
          'Kidase': ['Kidus'],
        },
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      await tester.tap(find.text(_l10n.playlistAddSongs));
      await tester.pumpAndSettle();
      expect(find.byType(AddSongsScreen), findsOneWidget);
      expect(_rowTitles(tester), [
        'Amlak',
        'Kidus',
        'Tselot',
        'Wudase',
        'ሰላም ለኪ',
      ]);

      FilledButton addButton() => tester.widget(find.byType(FilledButton));
      Finder addLabel(int count) => find.descendant(
        of: find.byType(FilledButton),
        matching: find.text(_l10n.playlistAddCount(count)),
      );
      expect(addButton().onPressed, isNull);
      expect(addLabel(0), findsOneWidget);

      // Already in the playlist: checked and can't be picked.
      Checkbox box(String title) => tester.widget(
        find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(TrackRow),
          ),
          matching: find.byType(Checkbox),
        ),
      );
      expect(box('Kidus').value, isTrue);
      expect(box('Kidus').onChanged, isNull);
      await tester.tap(find.text('Kidus'));
      await tester.pump();
      expect(addLabel(0), findsOneWidget);

      await tester.tap(find.text('Wudase'));
      await tester.enterText(find.byType(TextField), 'zerfe');
      await tester.pump();
      expect(_rowTitles(tester), ['Amlak', 'Tselot']);
      await tester.tap(find.text('Amlak'));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(box('Wudase').value, isTrue);
      expect(box('Amlak').value, isTrue);
      expect(addLabel(2), findsOneWidget);

      await tester.tap(addLabel(2));
      await tester.pumpAndSettle();
      expect(find.byType(AddSongsScreen), findsNothing);
      expect(_rowTitles(tester), ['Kidus', 'Wudase', 'Amlak']);
      expect(await app.stored(tester, ids['Kidase']!), [
        'Kidus',
        'Wudase',
        'Amlak',
      ]);
    });

    testWidgets('an empty playlist offers Add songs', (tester) async {
      await _pump(
        tester,
        playlists: {'Kidase': []},
        location: (ids) => _playlistRoute(ids['Kidase']!),
      );

      expect(find.text(_l10n.playlistEmptyTitle), findsOneWidget);
      await tester.tap(find.text(_l10n.playlistAddSongs));
      await tester.pumpAndSettle();
      expect(find.byType(AddSongsScreen), findsOneWidget);
    });
  });

  testWidgets('fits at 1.3× on a small phone in light and dark', (
    tester,
  ) async {
    useScreen(tester, size: const Size(320, 640), textScale: 1.3);
    for (final brightness in Brightness.values) {
      await _pump(
        tester,
        playlists: {
          'ቅዳሴ የሰንበት መዝሙሮች ለጥምቀት በዓል': ['Kidus', 'Amlak'],
        },
        phoneBrightness: brightness,
        tall: false,
      );
      expect(tester.takeException(), isNull, reason: '$brightness tab');

      await tester.tap(find.text(_l10n.playlistCreate));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness dialog');
      await tester.tap(find.text(_l10n.actionCancel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ቅዳሴ የሰንበት መዝሙሮች ለጥምቀት በዓል'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness page');

      await tester.tap(find.text(_l10n.playlistAddSongs));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness picker');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
