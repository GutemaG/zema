import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart' show ZemaDatabase;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/presentation/library_screen.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/audio_backend.dart';
import 'package:zema/features/settings/presentation/hidden_folders_screen.dart';
import 'package:zema/features/settings/presentation/hidden_songs_screen.dart';
import 'package:zema/features/settings/presentation/widgets/settings_row.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(1, '/storage/emulated/0/Music/1.mp3', title: 'Amlak'),
  scannedAudio(2, '/storage/emulated/0/Music/2.mp3', title: 'Kidus'),
  scannedAudio(
    3,
    '/storage/emulated/0/Recordings/note.m4a',
    title: 'Voice note',
    durationMs: 12000,
  ),
];

class _App {
  _App(this.db, this.backend, this.scanner);

  final ZemaDatabase db;
  final FakeAudioBackend backend;
  final GatedLibraryScanner scanner;
}

/// Opens Settings on a screen tall enough for every row.
Future<_App> _pump(
  WidgetTester tester, {
  AudioAccess access = AudioAccess.granted,
  Brightness phoneBrightness = Brightness.dark,
  Map<String, Object> savedPrefs = const {},
  String location = AppRoutes.home,
}) async {
  useScreen(tester, size: const Size(360, 2400));
  final app = _App(
    memoryDatabase(),
    FakeAudioBackend(),
    GatedLibraryScanner(_files()),
  );
  await pumpZemaApp(
    tester,
    location: location,
    libraryScanner: app.scanner,
    permissions: FakeAudioPermissionService(current: access),
    database: app.db,
    audioHandler: fakeAudioHandler(app.backend),
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true, ...savedPrefs},
  );
  // From Home, as a user gets there: the shell (which applies the
  // playback options) is then running.
  if (location == AppRoutes.home) {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }
  return app;
}

Finder _row(String label) => find.widgetWithText(SettingsRow, label);

String? _value(WidgetTester tester, String label) =>
    tester.widget<SettingsRow>(_row(label)).value;

Future<void> _tapRow(WidgetTester tester, String label) async {
  await tester.tap(_row(label));
  await tester.pumpAndSettle();
}

/// Goes to Library → Tracks and returns the song titles shown.
Future<List<String>> _libraryTitles(WidgetTester tester) async {
  tester.element(find.byType(Scaffold).first).go(AppRoutes.library);
  await tester.pumpAndSettle();
  return [
    for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
      row.track.title,
  ];
}

void main() {
  group('Settings → Library', () {
    testWidgets('Hidden folders lists them; Unhide brings the songs back', (
      tester,
    ) async {
      final app = await _pump(tester);
      await app.db.libraryDao.hideFolder('/storage/emulated/0/Music');
      await tester.pumpAndSettle();
      expect(_value(tester, _l10n.settingsHiddenFolders), '1');

      await _tapRow(tester, _l10n.settingsHiddenFolders);
      expect(find.byType(HiddenFoldersScreen), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('${_l10n.folderPhone}/Music'), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUnhide));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.hiddenFoldersEmptyTitle), findsOneWidget);

      expect(await _libraryTitles(tester), ['Amlak', 'Kidus']);
    });

    testWidgets('Hidden songs lists them; Unhide brings the song back', (
      tester,
    ) async {
      final app = await _pump(tester);
      await app.db.libraryDao.hideTracks([1, 2]);
      await tester.pumpAndSettle();
      expect(_value(tester, _l10n.settingsHiddenSongs), '2');

      await _tapRow(tester, _l10n.settingsHiddenSongs);
      expect(find.byType(HiddenSongsScreen), findsOneWidget);
      expect(find.text('Amlak'), findsOneWidget);
      expect(find.text('Kidus'), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUnhide).first);
      await tester.pumpAndSettle();
      expect(find.text('Amlak'), findsNothing);

      expect(await _libraryTitles(tester), ['Amlak']);
    });

    testWidgets('empty hidden lists explain how to hide things', (
      tester,
    ) async {
      await _pump(tester);
      expect(_value(tester, _l10n.settingsHiddenFolders), '0');

      await _tapRow(tester, _l10n.settingsHiddenSongs);
      expect(find.text(_l10n.hiddenSongsEmptyTitle), findsOneWidget);
      expect(find.text(_l10n.hiddenSongsEmptyMessage), findsOneWidget);
    });

    testWidgets('Rescan shows progress, then how many songs were found', (
      tester,
    ) async {
      final app = await _pump(tester);
      app.scanner
        ..hold = true
        ..files = [..._files(), scannedAudio(4, '/storage/emulated/0/4.mp3')];

      await tester.tap(_row(_l10n.settingsRescan));
      await tester.pump();
      expect(_value(tester, _l10n.settingsRescan), _l10n.settingsRescanning);
      expect(
        find.descendant(
          of: _row(_l10n.settingsRescan),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      app.scanner.release();
      await tester.pumpAndSettle();

      expect(_value(tester, _l10n.settingsRescan), isNull);
      // Three long enough songs; the voice note is too short.
      expect(find.text(_l10n.settingsRescanDone(3)), findsOneWidget);
    });

    testWidgets('a failed rescan offers Try again', (tester) async {
      final app = await _pump(tester);
      app.scanner.error = const ScanFailure('boom');

      await _tapRow(tester, _l10n.settingsRescan);

      expect(find.text(_l10n.libraryScanFailedSnack), findsOneWidget);
      app.scanner.error = null;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.settingsRescanDone(2)), findsOneWidget);
    });

    testWidgets('Rescan with no access opens the permission flow', (
      tester,
    ) async {
      final app = await _pump(tester, access: AudioAccess.denied);
      final scans = app.scanner.scans;

      await _tapRow(tester, _l10n.settingsRescan);

      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.text(_l10n.libraryAccessGrant), findsOneWidget);
      expect(app.scanner.scans, scans);
    });

    testWidgets('Ignore audio shorter than applies at once and is saved', (
      tester,
    ) async {
      final app = await _pump(tester);
      expect(
        _value(tester, _l10n.settingsMinDuration),
        _l10n.settingsSeconds(30),
      );
      final scans = app.scanner.scans;

      await _tapRow(tester, _l10n.settingsMinDuration);
      for (final label in [
        _l10n.settingsOff,
        _l10n.settingsSeconds(10),
        _l10n.settingsSeconds(30),
        _l10n.settingsSeconds(60),
      ]) {
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      await tester.tap(find.text(_l10n.settingsOff));
      await tester.pumpAndSettle();

      expect(_value(tester, _l10n.settingsMinDuration), _l10n.settingsOff);
      expect((await savedPreferences()).getInt('minTrackSeconds'), 0);
      expect(await _libraryTitles(tester), ['Amlak', 'Kidus', 'Voice note']);
      // No rescan was needed.
      expect(app.scanner.scans, scans);
    });

    testWidgets('a saved minimum is used from the start', (tester) async {
      await _pump(
        tester,
        savedPrefs: {'minTrackSeconds': 10},
        location: AppRoutes.library,
      );

      expect(
        [
          for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
            row.track.title,
        ],
        ['Amlak', 'Kidus', 'Voice note'],
      );
    });
  });

  group('Settings → Playback', () {
    testWidgets('defaults: none, on, Pause, on', (tester) async {
      final app = await _pump(tester);

      expect(_value(tester, _l10n.settingsSleepDefault), _l10n.settingsNone);
      expect(
        _value(tester, _l10n.settingsInterruptions),
        _l10n.settingsInterruptionsPause,
      );
      Switch switchIn(String label) => tester.widget(
        find.descendant(of: _row(label), matching: find.byType(Switch)),
      );
      expect(switchIn(_l10n.settingsPauseOnUnplug).value, isTrue);
      expect(switchIn(_l10n.settingsGapless).value, isTrue);
      expect(app.backend.options, const PlaybackOptions());
    });

    testWidgets('Sleep timer default is picked and saved', (tester) async {
      await _pump(tester);

      await _tapRow(tester, _l10n.settingsSleepDefault);
      await tester.tap(find.text(_l10n.sleepMinutes(45)));
      await tester.pumpAndSettle();

      expect(
        _value(tester, _l10n.settingsSleepDefault),
        _l10n.sleepMinutes(45),
      );
      expect(
        (await savedPreferences()).getString('sleepTimerDefault'),
        'minutes45',
      );
    });

    testWidgets('the unplug and gapless switches reach the player', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _tapRow(tester, _l10n.settingsPauseOnUnplug);
      // The switch itself works too.
      await tester.tap(
        find.descendant(
          of: _row(_l10n.settingsGapless),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        app.backend.options,
        const PlaybackOptions(pauseOnUnplug: false, gapless: false),
      );
      final prefs = await savedPreferences();
      expect(prefs.getBool('pauseOnUnplug'), isFalse);
      expect(prefs.getBool('gapless'), isFalse);
    });

    testWidgets('Lower volume reaches the player and says calls pause', (
      tester,
    ) async {
      final app = await _pump(tester);

      await _tapRow(tester, _l10n.settingsInterruptions);
      expect(find.text(_l10n.settingsInterruptionsNote), findsOneWidget);
      await tester.tap(find.text(_l10n.settingsInterruptionsDuck));
      await tester.pumpAndSettle();

      expect(
        _value(tester, _l10n.settingsInterruptions),
        _l10n.settingsInterruptionsDuck,
      );
      expect(app.backend.options?.duckOnInterruption, isTrue);
      expect((await savedPreferences()).getBool('duckOnInterruption'), isTrue);
    });

    testWidgets('saved values are shown and applied after a restart', (
      tester,
    ) async {
      final app = await _pump(
        tester,
        savedPrefs: {
          'sleepTimerDefault': 'endOfSong',
          'pauseOnUnplug': false,
          'duckOnInterruption': true,
          'gapless': false,
        },
      );

      expect(_value(tester, _l10n.settingsSleepDefault), _l10n.sleepEndOfSong);
      expect(
        _value(tester, _l10n.settingsInterruptions),
        _l10n.settingsInterruptionsDuck,
      );
      expect(
        app.backend.options,
        const PlaybackOptions(
          pauseOnUnplug: false,
          duckOnInterruption: true,
          gapless: false,
        ),
      );
    });
  });

  testWidgets('switch rows read their state to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(
      tester.getSemantics(_row(_l10n.settingsGapless)),
      isSemantics(
        label: _l10n.settingsGapless,
        hasToggledState: true,
        isToggled: true,
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('pages and sheets fit at 1.3× on a small phone, light and dark', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final app = await _pump(tester, phoneBrightness: brightness);
      await app.db.libraryDao.hideFolder(
        '/storage/emulated/0/Music/ቅዱስ ያሬድ የዜማ መዝሙሮች ስብስብ ቁጥር ሁለት',
      );
      await app.db.libraryDao.hideTracks([1]);
      useScreen(tester, size: const Size(320, 2400), textScale: 1.3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness settings');

      await _tapRow(tester, _l10n.settingsInterruptions);
      expect(tester.takeException(), isNull, reason: '$brightness sheet');
      await tester.tapAt(const Offset(160, 40));
      await tester.pumpAndSettle();

      for (final page in [
        _l10n.settingsHiddenFolders,
        _l10n.settingsHiddenSongs,
      ]) {
        await _tapRow(tester, page);
        expect(tester.takeException(), isNull, reason: '$brightness $page');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
