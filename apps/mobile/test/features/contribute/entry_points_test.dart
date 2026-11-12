import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/widgets/sign_in_prompt.dart';
import 'package:zema/features/contribute/application/contribution_starts.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/features/contribute/presentation/recording_step.dart';
import 'package:zema/features/contribute/presentation/sync_step.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/application/track_lyrics.dart';
import 'package:zema/features/player/presentation/mini_player.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_catalog.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/fake_player.dart';
import '../../helpers/memory_lyrics.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

const selam = Song(
  id: 'selam-lezih-bet',
  title: 'Selam Lezih Bet',
  artist: 'Choir',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('Selam lezih bet'), LyricLine('Selam lekulu')],
    ),
  ],
  playOrder: ['v1'],
);

/// A YouTube recording with a timing, and the phone's file without one.
const youtube = Recording(
  id: 'rec-yt',
  songId: 'selam-lezih-bet',
  source: RecordingSource.youtube,
  youtubeId: 'dQw4w9WgXcQ',
);
const local = Recording(
  id: 'rec-local',
  songId: 'selam-lezih-bet',
  source: RecordingSource.localFile,
  artist: 'Choir',
  fileName: 'selam.mp3',
);
final youtubeTiming = SyncTiming(
  recordingId: youtube.id,
  starts: const [Duration(seconds: 1), Duration(seconds: 2)],
);

Track track(int id, String path, {String? artist}) => Track(
  id: id,
  mediaStoreId: id,
  uri: 'content://media/$id',
  path: path,
  title: 'Kidus',
  artist: artist,
  duration: const Duration(minutes: 3),
  sizeBytes: 1,
  dateAdded: DateTime.utc(2026),
);

RecordingInfo info(Recording recording, {bool synced = false}) =>
    (recording: recording, synced: synced);

/// Lets database work and the index refresh finish, then settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('recordingToSync', () {
    test('a local recording without a timing that a track plays', () {
      final mine = track(1, '/music/selam.mp3');
      expect(recordingToSync([info(youtube), info(local)], [mine]), (
        recording: local,
        track: mine,
      ));
    });

    test('none when it is synced, another file, or not a local file', () {
      final mine = track(1, '/music/selam.mp3');
      expect(recordingToSync([info(local, synced: true)], [mine]), isNull);
      expect(
        recordingToSync([info(local)], [track(2, '/music/other.mp3')]),
        isNull,
      );
      expect(recordingToSync([info(youtube)], [mine]), isNull);
    });

    test('the tracks are tried in order (the playing one first)', () {
      final other = Recording(
        id: 'rec-2',
        songId: selam.id,
        source: RecordingSource.localFile,
        fileName: 'other.mp3',
      );
      final first = track(2, '/music/other.mp3');
      expect(
        recordingToSync(
          [info(local), info(other)],
          [first, track(1, '/music/selam.mp3')],
        )!.recording,
        other,
      );
    });
  });

  test('a track with no lyrics starts a new song with its details', () {
    final draft = newSongDraftFor(
      track(4, '/music/Kidus.mp3', artist: 'Choir'),
    );
    expect(draft.kind, ContributionKind.newSong);
    expect(draft.title, 'Kidus');
    expect(draft.song.artist, 'Choir');
    expect(draft.trackId, 4);
    expect(draft.recording!.source, RecordingSource.localFile);
    expect(draft.recording!.fileName, 'Kidus.mp3');
    expect(draft.recording!.duration, const Duration(minutes: 3));
    expect(draft.step, DraftStep.lyrics);
  });

  late ZemaDatabase db;
  late FakeAuthRepository auth;
  late FakeCatalogRepository catalog;

  setUp(() {
    db = memoryDatabase();
    auth = FakeAuthRepository(user: testUser);
    catalog = FakeCatalogRepository(
      lyrics: MemoryLyricsRepository(
        [selam],
        recordings: [youtube, local],
        timings: [youtubeTiming],
      ),
    )..versions[selam.id] = 5;
  });

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.library,
    List<ScannedAudio> audio = const [],
    bool backendConfigured = true,
    Size size = const Size(400, 900),
    double textScale = 1,
    Brightness brightness = Brightness.dark,
    FakeAudioBackend? player,
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: location,
      auth: auth,
      database: db,
      catalog: catalog,
      backendConfigured: backendConfigured,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      libraryScanner: FakeLibraryScanner(audio),
      audioHandler: fakeAudioHandler(player ?? FakeAudioBackend()),
      savedPrefs: {
        AccountChoiceController.key: true,
        LibraryAccessController.explainedKey: true,
      },
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  void go(WidgetTester tester, String location) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<List<ContributionDraft>> savedDrafts(WidgetTester tester) async {
    await tester.pump(draftSaveDelay * 2);
    return [
      for (final row in await db.select(db.drafts).get())
        ContributionDraft.fromJson(jsonDecode(row.draft)),
    ];
  }

  group('Search with no results', () {
    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byType(TextField), query);
      await settle(tester);
    }

    Finder addSong() => find.text(_l10n.contributeEntryAddSongLyrics);

    testWidgets('Add this song\'s lyrics opens S19 with the title', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.search);
      await search(tester, 'Mezmur zelealem ');
      expect(find.text(_l10n.libraryNoResultsTitle), findsOneWidget);

      await tap(tester, addSong());
      expect(find.byType(LyricsStep), findsOneWidget);
      final draft = (await savedDrafts(tester)).single;
      expect(draft.kind, ContributionKind.newSong);
      expect(draft.title, 'Mezmur zelealem');
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, _l10n.contributeFieldTitle),
            )
            .controller!
            .text,
        'Mezmur zelealem',
      );
    });

    testWidgets('a guest starts without signing in', (tester) async {
      auth = FakeAuthRepository();
      await start(tester, location: AppRoutes.search);
      await search(tester, 'Mezmur zelealem');
      await tap(tester, addSong());
      expect(find.byType(SignInPrompt), findsNothing);
      expect(find.byType(LyricsStep), findsOneWidget);
      expect((await savedDrafts(tester)).single.title, 'Mezmur zelealem');
    });

    testWidgets('without a backend it is still offered', (tester) async {
      await start(tester, location: AppRoutes.search, backendConfigured: false);
      await search(tester, 'Mezmur zelealem');
      await tap(tester, addSong());
      expect(find.byType(LyricsStep), findsOneWidget);
    });
  });

  group('A track with no lyrics', () {
    /// Plays the unlinked Kidus and shows its lyrics on Now Playing.
    Future<void> nowPlaying(
      WidgetTester tester, {
      bool backendConfigured = true,
    }) async {
      final player = FakeAudioBackend();
      await start(
        tester,
        audio: [scannedAudio(1, '/m/Kidus.mp3', title: 'Kidus', artist: 'Ze')],
        backendConfigured: backendConfigured,
        player: player,
      );
      await tap(tester, find.text('Kidus').first);
      await tap(tester, find.byType(MiniPlayer));
      await tap(tester, find.byTooltip(_l10n.playerShowLyrics));
      expect(find.text(_l10n.playerNoLyrics), findsOneWidget);
    }

    Finder addLyrics() =>
        find.widgetWithText(OutlinedButton, _l10n.contributeAddLyrics);

    testWidgets('Add lyrics opens S19 with its title, artist and track', (
      tester,
    ) async {
      await nowPlaying(tester);
      await tap(tester, addLyrics());

      expect(find.byType(LyricsStep), findsOneWidget);
      final draft = (await savedDrafts(tester)).single;
      final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
      expect(draft.title, 'Kidus');
      expect(draft.song.artist, 'Ze');
      expect(draft.trackId, tracks.single.id);
      expect(draft.recording!.source, RecordingSource.localFile);
      expect(draft.recording!.fileName, 'Kidus.mp3');
    });

    testWidgets('a guest starts without signing in', (tester) async {
      auth = FakeAuthRepository();
      await nowPlaying(tester);
      await tap(tester, addLyrics());
      expect(find.byType(SignInPrompt), findsNothing);
      expect(await savedDrafts(tester), hasLength(1));
    });

    testWidgets('without a backend lyrics can still be added', (tester) async {
      await nowPlaying(tester, backendConfigured: false);
      expect(find.text(_l10n.songMatchLyrics), findsOneWidget);
      await tap(tester, addLyrics());
      expect(await savedDrafts(tester), hasLength(1));
    });
  });

  group('Song detail', () {
    /// Song detail of Selam, with the phone's selam.mp3 linked to it.
    Future<void> detail(
      WidgetTester tester, {
      Size size = const Size(400, 900),
      double textScale = 1,
      Brightness brightness = Brightness.dark,
    }) async {
      await start(
        tester,
        audio: [scannedAudio(1, '/m/selam.mp3', title: 'Selam Lezih Bet')],
        size: size,
        textScale: textScale,
        brightness: brightness,
      );
      go(tester, AppRoutes.song(selam.id));
      // The song downloads, then its recordings and their timings load.
      await settle(tester);
      await settle(tester);
      await tap(tester, find.byTooltip(_l10n.songDetailMoreOptions));
    }

    testWidgets('the menu offers each way to contribute, and Report', (
      tester,
    ) async {
      await detail(tester);
      expect(find.text(_l10n.contributeCorrectionSuggest), findsOneWidget);
      expect(find.text(_l10n.contributeEntryLinkRecording), findsOneWidget);
      expect(find.text(_l10n.contributeEntrySyncRecording), findsOneWidget);
      expect(find.text(_l10n.reportLyrics), findsOneWidget);
    });

    testWidgets('Suggest a correction opens S19 filled with the song', (
      tester,
    ) async {
      await detail(tester);
      await tap(tester, find.text(_l10n.contributeCorrectionSuggest));

      expect(find.byType(LyricsStep), findsOneWidget);
      expect(find.text(_l10n.contributeCorrectionNote), findsOneWidget);
      expect(find.text('Selam lezih bet\nSelam lekulu'), findsOneWidget);
      final draft = (await savedDrafts(tester)).single;
      expect(draft.kind, ContributionKind.editLyrics);
      expect(draft.songId, selam.id);
      expect(draft.baseVersion, 5);
      expect(draft.song, selam);
      final contribution = draft.toContribution();
      expect(contribution.kind.wire, 'edit_lyrics');
      expect(contribution.songId, selam.id);
      expect(contribution.baseVersion, 5);
    });

    testWidgets('Link a recording opens S20 for the song', (tester) async {
      await detail(tester);
      await tap(tester, find.text(_l10n.contributeEntryLinkRecording));

      expect(find.byType(RecordingStep), findsOneWidget);
      final draft = (await savedDrafts(tester)).single;
      expect(draft.kind, ContributionKind.recording);
      expect(draft.songId, selam.id);
      expect(draft.song, selam);
      expect(draft.step, DraftStep.recording);
    });

    testWidgets('Sync this recording opens S21 for the phone\'s recording '
        'without timings', (tester) async {
      await detail(tester);
      await tap(tester, find.text(_l10n.contributeEntrySyncRecording));

      expect(find.byType(SyncStep), findsOneWidget);
      final draft = (await savedDrafts(tester)).single;
      final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
      expect(draft.kind, ContributionKind.syncTiming);
      expect(draft.songId, selam.id);
      expect(draft.recording, local);
      expect(draft.trackId, tracks.single.id);
      expect(draft.step, DraftStep.sync);
    });

    testWidgets('no Sync this recording when the recording has a timing', (
      tester,
    ) async {
      catalog = FakeCatalogRepository(
        lyrics: MemoryLyricsRepository(
          [selam],
          recordings: [local],
          timings: [
            SyncTiming(
              recordingId: local.id,
              starts: const [Duration(seconds: 1), Duration(seconds: 2)],
            ),
          ],
        ),
      );
      await detail(tester);
      expect(find.text(_l10n.contributeCorrectionSuggest), findsOneWidget);
      expect(find.text(_l10n.contributeEntrySyncRecording), findsNothing);
    });

    testWidgets('a guest starts without signing in', (tester) async {
      auth = FakeAuthRepository();
      await detail(tester);
      await tap(tester, find.text(_l10n.contributeEntryLinkRecording));
      expect(find.byType(SignInPrompt), findsNothing);
      expect(await savedDrafts(tester), hasLength(1));
    });

    for (final brightness in Brightness.values) {
      testWidgets('the menu fits a small phone at 1.3× text ($brightness)', (
        tester,
      ) async {
        await detail(
          tester,
          size: const Size(360, 640),
          textScale: 1.3,
          brightness: brightness,
        );
        expect(find.text(_l10n.contributeEntrySyncRecording), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
