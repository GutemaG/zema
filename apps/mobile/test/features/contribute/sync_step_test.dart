import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/recording_step.dart';
import 'package:zema/features/contribute/presentation/sync_step.dart';
import 'package:zema/features/lyrics/presentation/lyrics_view.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_contribute.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/fake_player.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// Four sung lines: a verse of two, then its chorus twice.
const lyrics = Song(
  id: '',
  title: 'Selam',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('Verse line one'), LyricLine('Verse line two')],
    ),
    LyricSection(
      id: 'c1',
      kind: SectionKind.chorus,
      lines: [LyricLine('The chorus')],
    ),
  ],
  playOrder: ['v1', 'c1', 'c1'],
);

const shared = Recording(
  id: 'rec-1',
  songId: '',
  source: RecordingSource.telegram,
  fileName: 'Selam.ogg',
);

const sharedDraft = ContributionDraft(
  song: lyrics,
  recording: shared,
  audioPath: '/data/files/shared_audio/1-Selam.ogg',
  step: DraftStep.sync,
);

void main() {
  late ZemaDatabase db;
  late FakeSyncPlayer player;
  late FakeAudioBackend mainPlayer;

  setUp(() {
    db = memoryDatabase();
    player = FakeSyncPlayer();
    mainPlayer = FakeAudioBackend();
  });

  Future<void> open(
    WidgetTester tester, {
    ContributionDraft draft = sharedDraft,
    String? location,
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    final id = await db.draftsDao.create(draft, now: DateTime.utc(2026, 11, 2));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: location ?? AppRoutes.draft(id),
      auth: FakeAuthRepository(user: testUser),
      database: db,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
      syncPlayer: player,
      audioHandler: fakeAudioHandler(mainPlayer),
      libraryScanner: FakeLibraryScanner([
        scannedAudio(7, '/music/Selam.mp3', title: 'Selam'),
      ]),
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<ContributionDraft> saved(WidgetTester tester) async {
    await tester.pump(draftSaveDelay * 2);
    final row = (await db.select(db.drafts).get()).single;
    return ContributionDraft.fromJson(jsonDecode(row.draft));
  }

  Finder big(String label) => find.widgetWithText(FilledButton, label);

  Future<void> play(WidgetTester tester) => tap(
    tester,
    find.byTooltip(player.isPlaying ? _l10n.playerPause : _l10n.playerPlay),
  );

  Future<void> tapAt(WidgetTester tester, num seconds) async {
    player.position = s(seconds);
    await tap(tester, big(_l10n.contributeSyncTap));
  }

  testWidgets('every sung line is a row, untimed; play, then tap', (
    tester,
  ) async {
    await open(tester);
    expect(player.loaded, [Uri.file(sharedDraft.audioPath!)]);
    expect(find.text('Verse line one'), findsOneWidget);
    expect(find.text('The chorus'), findsNWidgets(2), reason: 'each repeat');
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text(_l10n.contributeSyncTapHint), findsOneWidget);
    expect(find.text('0:00.0 / 3:00'), findsOneWidget);

    // Paused, the big button plays.
    await tap(tester, big(_l10n.contributeSyncPressPlay));
    expect(player.isPlaying, isTrue);
    expect(big(_l10n.contributeSyncTap), findsOneWidget);
    await play(tester);
    expect(player.isPlaying, isFalse, reason: 'the bar pauses');
  });

  testWidgets('each tap times the next line at the position; done goes to '
      'review', (tester) async {
    await open(tester);
    await play(tester);
    await tapAt(tester, 1.24);
    expect(find.text(formatSyncTime(s(1.24))), findsWidgets);
    expect((await saved(tester)).starts, [s(1.24), null, null, null]);

    await tapAt(tester, 3);
    await tapAt(tester, 6.5);
    await tapAt(tester, 12);
    expect(find.text(_l10n.contributeSyncTapHint), findsNothing);
    final draft = await saved(tester);
    expect(draft.starts, [s(1.24), s(3), s(6.5), s(12)]);
    expect(draft.synced, isTrue);

    await tap(tester, big(_l10n.contributeNextReview));
    expect((await saved(tester)).step, DraftStep.review);
  });

  testWidgets('Undo clears the last tap and that line is next again', (
    tester,
  ) async {
    await open(tester);
    await play(tester);
    await tapAt(tester, 1);
    await tapAt(tester, 2);
    await tap(tester, find.text(_l10n.contributeSyncUndo));
    expect((await saved(tester)).starts, [s(1), null, null, null]);
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('a timed line nudges by 0.1 s, keeps going while held, and '
      'never passes its neighbour', (tester) async {
    await open(
      tester,
      draft: sharedDraft.copyWith(starts: [s(1), s(2), s(3), null]),
    );
    await tap(tester, find.text('Verse line two'));
    await tap(tester, find.bySemanticsLabel(_l10n.contributeSyncLater));
    expect((await saved(tester)).starts[1], s(2.1));
    await tap(tester, find.bySemanticsLabel(_l10n.contributeSyncEarlier));
    expect((await saved(tester)).starts[1], s(2));

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel(_l10n.contributeSyncLater)),
    );
    await tester.pump(const Duration(seconds: 3));
    await gesture.up();
    await tester.pumpAndSettle();
    expect((await saved(tester)).starts[1], s(2.9), reason: 'stops before 3');
  });

  testWidgets('Redo from here clears it and later lines, and plays from 3 s '
      'before', (tester) async {
    await open(
      tester,
      draft: sharedDraft.copyWith(starts: [s(1), s(5), s(9), s(12)]),
    );
    await tap(tester, find.text('Verse line two'));
    await tap(tester, find.text(_l10n.contributeSyncRedo));
    expect((await saved(tester)).starts, [s(1), null, null, null]);
    expect(player.seeks.last, s(2));
    expect(player.isPlaying, isTrue);
    expect(find.text(_l10n.contributeSyncTapHint), findsOneWidget);
  });

  testWidgets('−5 s and the speed', (tester) async {
    await open(tester);
    player.position = s(12);
    await tester.pump();
    await tap(tester, find.text(_l10n.contributeSyncBack5));
    expect(player.seeks.last, s(7));
    await tap(tester, find.text(_l10n.contributeSyncSpeedNormal));
    expect(player.speeds, [0.75]);
    await tap(tester, find.text(_l10n.contributeSyncSpeedSlow));
    expect(player.speeds, [0.75, 1.0]);
  });

  testWidgets('Skip sends the text only', (tester) async {
    await open(
      tester,
      draft: sharedDraft.copyWith(starts: [s(1), null, null, null]),
    );
    await tap(tester, find.byTooltip(_l10n.contributeSyncMore));
    await tap(tester, find.text(_l10n.contributeSyncSkip));
    final draft = await saved(tester);
    expect(draft.starts, isEmpty);
    expect(draft.step, DraftStep.review);
  });

  testWidgets('the main player pauses, and so does syncing in the '
      'background; closing frees the player', (tester) async {
    mainPlayer.playing = true;
    await open(tester);
    expect(mainPlayer.playing, isFalse);

    await play(tester);
    // Into the background and back with no time passing (frames stop
    // while paused).
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(player.isPlaying, isFalse);

    await tap(tester, find.byType(CloseButton));
    expect(player.disposed, isTrue);
  });

  testWidgets('a song on the phone plays from the library', (tester) async {
    // The library syncs under the tabs.
    await open(tester, location: AppRoutes.contribute);
    await tester.pumpWidget(const SizedBox());
    await db.delete(db.drafts).go();
    final track = (await db.select(db.tracks).get()).single;
    await open(
      tester,
      draft: ContributionDraft(
        song: lyrics,
        recording: const Recording(
          id: 'rec-1',
          songId: '',
          source: RecordingSource.localFile,
          fileName: 'Selam.mp3',
        ),
        trackId: track.id,
        step: DraftStep.sync,
      ),
    );
    expect(player.loaded.last, Uri.parse(track.uri));
  });

  testWidgets('a recording that is gone says so and goes back to S20', (
    tester,
  ) async {
    player.broken = true;
    await open(tester);
    expect(find.text(_l10n.contributeSyncNoAudio), findsOneWidget);
    await tap(tester, find.text(_l10n.contributeSyncChooseRecording));
    expect(find.byType(RecordingStep), findsOneWidget);
  });

  testWidgets('times for lyrics that changed start over', (tester) async {
    await open(tester, draft: sharedDraft.copyWith(starts: [s(1), s(2)]));
    expect((await saved(tester)).starts, [null, null, null, null]);
  });

  group('Focus and Preview', () {
    Future<void> focus(WidgetTester tester) =>
        tap(tester, find.byTooltip(_l10n.contributeSyncFocus));

    Finder area(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(InkWell));

    testWidgets('Focus shows the line before with its time, the next line '
        'with its block, and the one after; it taps the same lines', (
      tester,
    ) async {
      await open(
        tester,
        draft: sharedDraft.copyWith(starts: [s(1), s(3), null, null]),
      );
      await focus(tester);
      expect(find.text('Verse line two'), findsOneWidget);
      expect(
        find.text(_l10n.contributeSyncTimedAt(formatSyncTime(s(3)))),
        findsOneWidget,
      );
      expect(find.text('CHORUS'), findsOneWidget);
      expect(find.text('The chorus'), findsNWidgets(2), reason: 'now, next');
      expect(find.text('Verse line one'), findsNothing);

      // Paused, the area plays; playing, it taps.
      await tap(tester, area(_l10n.contributeSyncPressPlay));
      expect(player.isPlaying, isTrue);
      player.position = s(6.2);
      await tap(tester, area(_l10n.contributeSyncHearIt));
      expect((await saved(tester)).starts, [s(1), s(3), s(6.2), null]);

      await tap(tester, find.text(_l10n.contributeSyncUndo));
      expect((await saved(tester)).starts, [s(1), s(3), null, null]);
      await tap(tester, find.text(_l10n.contributeSyncBack5));
      expect(player.seeks.last, s(1.2));
      await tap(tester, find.text(_l10n.playerPause));
      expect(player.isPlaying, isFalse);
    });

    testWidgets('switching views keeps the times, the position and playback', (
      tester,
    ) async {
      await open(tester);
      await play(tester);
      player.position = s(2);
      await tapAt(tester, 2);
      await focus(tester);
      expect(player.isPlaying, isTrue);
      player.position = s(4);
      await tap(tester, area(_l10n.contributeSyncHearIt));
      await tap(tester, find.byTooltip(_l10n.contributeSyncList));
      expect(player.isPlaying, isTrue);
      expect(player.loaded, hasLength(1), reason: 'the same player');
      expect(find.text(formatSyncTime(s(4))), findsWidgets);
      expect((await saved(tester)).starts, [s(2), s(4), null, null]);
    });

    testWidgets('once every line is timed, Focus goes on to review', (
      tester,
    ) async {
      await open(
        tester,
        draft: sharedDraft.copyWith(starts: [s(1), s(2), s(3), s(4)]),
      );
      await focus(tester);
      expect(find.text(_l10n.contributeSyncAllTimed), findsOneWidget);
      await tap(tester, area(_l10n.contributeNextReview));
      expect((await saved(tester)).step, DraftStep.review);
    });

    testWidgets('Preview plays from the start in the lyrics view, '
        'highlighting by the times', (tester) async {
      await open(
        tester,
        draft: sharedDraft.copyWith(starts: [s(1), s(3), s(6), null]),
      );
      player.position = s(30);
      await tester.pump();
      await tap(tester, find.text(_l10n.contributeSyncPreview));
      expect(find.byType(LyricsLines), findsOneWidget);
      expect(player.seeks.last, Duration.zero);
      expect(player.isPlaying, isTrue);

      LyricsLines lines() => tester.widget(find.byType(LyricsLines));
      // A position event lands after one frame and shows on the next.
      Future<void> moveTo(num seconds) async {
        player.position = s(seconds);
        await tester.pump();
        await tester.pump();
      }

      expect(lines().current, isNull);
      await moveTo(3.5);
      expect(find.text('${formatSyncTime(s(3.5))} / 3:00'), findsOneWidget);
      expect(lines().current, 1);
      await moveTo(7);
      expect(lines().current, 2);

      await tap(tester, find.text(_l10n.contributeSyncEndPreview));
      expect(player.isPlaying, isFalse);
      expect(find.byType(LyricsLines), findsNothing);
      expect(find.text(_l10n.contributeSyncTapHint), findsOneWidget);
    });

    testWidgets('Preview needs a time first', (tester) async {
      await open(tester);
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(
                of: find.text(_l10n.contributeSyncPreview),
                matching: find.byWidgetPredicate((w) => w is TextButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      await open(
        tester,
        brightness: brightness,
        textScale: 1.3,
        size: const Size(360, 640),
        draft: sharedDraft.copyWith(
          song: const Song(
            id: '',
            title: 'Selam',
            sections: [
              LyricSection(
                id: 'v1',
                kind: SectionKind.verse,
                lines: [LyricLine('እግዚአብሔርን አመስግኑ ቸር ነውና ለዘላለም ምሕረቱ')],
              ),
            ],
            playOrder: ['v1', 'v1', 'v1'],
          ),
          starts: [s(61.5), null, null],
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.textContaining('እግዚአብሔርን').first);
      await tester.pumpAndSettle();
      await tap(tester, find.textContaining('እግዚአብሔርን').first);
      expect(find.text(_l10n.contributeSyncRedo), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byTooltip(_l10n.contributeSyncFocus));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text(_l10n.contributeSyncPreview));
      expect(tester.takeException(), isNull);
    });
  }
}
