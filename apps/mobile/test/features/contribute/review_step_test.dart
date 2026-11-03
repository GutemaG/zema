import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/widgets/sign_in_prompt.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/contribute_screen.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/features/contribute/presentation/recording_step.dart';
import 'package:zema/features/contribute/presentation/correction_changes.dart';
import 'package:zema/features/contribute/presentation/review_step.dart';
import 'package:zema/features/contribute/presentation/sync_step.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_catalog.dart';
import '../../helpers/fake_contribute.dart';
import '../../helpers/fake_contributions.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/memory_lyrics.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// Four sung lines: a verse of two, then its chorus twice.
const lyrics = Song(
  id: '',
  title: 'Selam',
  artist: 'Abebe Choir',
  album: 'Mezmur',
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

const onPhone = Recording(
  id: 'rec-1',
  songId: '',
  source: RecordingSource.localFile,
  duration: Duration(minutes: 3, seconds: 5),
  fileName: 'Selam.mp3',
);

/// Synced to a song on the phone, ready to send.
final syncedDraft = ContributionDraft(
  song: lyrics,
  recording: onPhone,
  starts: [s(1), s(3), s(6.5), s(12)],
  trackId: 7,
  step: DraftStep.review,
);

/// Sends wait for [gate] when it is set; [calls] counts them.
class _GatedContributions extends FakeContributionRepository {
  Completer<void>? gate;
  var calls = 0;

  @override
  Future<String> submit(Contribution contribution) async {
    calls++;
    await gate?.future;
    return super.submit(contribution);
  }
}

void main() {
  late ZemaDatabase db;
  late _GatedContributions contributions;

  setUp(() {
    db = memoryDatabase();
    contributions = _GatedContributions();
  });

  Future<void> open(
    WidgetTester tester, {
    ContributionDraft? draft,
    FakeCatalogRepository? catalog,
    String? location,
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    Size size = const Size(400, 1200),
    FakeAuthRepository? auth,
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    final id = await db.draftsDao.create(
      draft ?? syncedDraft,
      now: DateTime.utc(2026, 11, 2),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: location ?? AppRoutes.draft(id),
      auth: auth ?? FakeAuthRepository(user: testUser),
      database: db,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
      syncPlayer: FakeSyncPlayer(),
      contributions: contributions,
      catalog: catalog,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/music/Tizita.mp3', title: 'Tizita', artist: 'Mulatu'),
      ]),
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<List<ContributionDraft>> drafts(WidgetTester tester) async {
    await tester.pump(draftSaveDelay * 2);
    return [
      for (final row in await db.select(db.drafts).get())
        ContributionDraft.fromJson(jsonDecode(row.draft)),
    ];
  }

  Future<List<OwnCopyRow>> copies() => db.select(db.ownCopies).get();

  Finder submit() => find.widgetWithText(FilledButton, _l10n.contributeSubmit);

  testWidgets('shows the song, the lyrics in play order, the recording and '
      'the sync status', (tester) async {
    await open(tester);
    expect(find.byType(ReviewStep), findsOneWidget);
    expect(find.text('Selam'), findsOneWidget);
    expect(find.text('Abebe Choir · Mezmur'), findsOneWidget);
    expect(
      find.text(_l10n.contributeBlockVerse(1).toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(_l10n.lyricsChorus.toUpperCase()),
      findsNWidgets(2),
      reason: 'each time it is sung',
    );
    expect(find.text('The chorus'), findsNWidgets(2));
    final verse = tester.getTopLeft(find.text('Verse line two')).dy;
    final chorus = tester.getTopLeft(find.text('The chorus').first).dy;
    expect(verse, lessThan(chorus), reason: 'in play order');
    expect(find.text('Selam.mp3'), findsOneWidget);
    expect(find.text('3:05'), findsOneWidget);
    expect(find.text(_l10n.contributeReviewSynced), findsOneWidget);
    expect(submit(), findsOneWidget);
  });

  testWidgets('text only, YouTube and no recording', (tester) async {
    await open(tester, draft: syncedDraft.copyWith(starts: [s(1), null]));
    expect(find.text(_l10n.contributeReviewTextOnly), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.delete(db.drafts).go();

    await open(
      tester,
      draft: syncedDraft.copyWith(
        recording: () => const Recording(
          id: 'rec-1',
          songId: '',
          source: RecordingSource.youtube,
          youtubeId: 'dQw4w9WgXcQ',
        ),
        starts: const [],
        videoTitle: () => 'Selam (live)',
      ),
    );
    expect(find.text(_l10n.contributeReviewYoutube), findsOneWidget);
    expect(find.text('Selam (live)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.delete(db.drafts).go();

    await open(
      tester,
      draft: syncedDraft.copyWith(recording: () => null, starts: const []),
    );
    expect(find.text(_l10n.contributeReviewNoRecording), findsOneWidget);
    expect(find.text(_l10n.contributeReviewTextOnly), findsOneWidget);
  });

  group('Edit goes to its step', () {
    for (final (label, step, widget) in [
      (_l10n.contributeReviewEditSong, DraftStep.lyrics, LyricsStep),
      (_l10n.contributeReviewEditLyrics, DraftStep.lyrics, LyricsStep),
      (_l10n.contributeReviewEditRecording, DraftStep.recording, RecordingStep),
      (_l10n.contributeReviewEditSync, DraftStep.sync, SyncStep),
    ]) {
      testWidgets(label, (tester) async {
        await open(tester);
        await tap(tester, find.bySemanticsLabel(label));
        expect(find.byType(widget), findsOneWidget);
        expect((await drafts(tester)).single.step, step);
      });
    }

    testWidgets('timings of a YouTube video go to the recording', (
      tester,
    ) async {
      await open(
        tester,
        draft: syncedDraft.copyWith(
          recording: () => const Recording(
            id: 'rec-1',
            songId: '',
            source: RecordingSource.youtube,
            youtubeId: 'dQw4w9WgXcQ',
          ),
          starts: const [],
        ),
      );
      await tap(tester, find.bySemanticsLabel(_l10n.contributeReviewEditSync));
      expect(find.byType(RecordingStep), findsOneWidget);
    });
  });

  group('Save on this phone', () {
    Finder save() =>
        find.widgetWithText(OutlinedButton, _l10n.contributeSaveLocal);

    testWidgets('a guest saves without signing in; the draft stays', (
      tester,
    ) async {
      await open(tester, auth: FakeAuthRepository());
      expect(find.text(_l10n.contributeReviewGuest), findsOneWidget);
      await tap(tester, save());

      expect(contributions.calls, 0);
      expect(find.byType(SignInPrompt), findsNothing);
      final draftId = (await db.select(db.drafts).get()).single.id;
      final copy = (await copies()).single;
      expect(copy.contributionId, localCopyId(draftId));
      expect(copy.trackId, 7);
      expect(Song.fromJson(jsonDecode(copy.song)).title, 'Selam');
      expect(
        SyncTiming.fromJson(jsonDecode(copy.timing!)).starts,
        syncedDraft.starts,
      );
      expect(find.byType(ContributeScreen), findsOneWidget);
      expect(find.text(_l10n.contributeSavedLocal), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(_l10n.contributeDraftSavedLocal('')),
        findsOneWidget,
      );
    });

    testWidgets('saving again replaces the saved lyrics', (tester) async {
      await open(tester, auth: FakeAuthRepository());
      await tap(tester, save());
      await tap(tester, find.text('Selam'));
      await tap(tester, save());
      expect(await copies(), hasLength(1));
    });

    testWidgets('broken lyrics are not saved', (tester) async {
      await open(
        tester,
        draft: syncedDraft.copyWith(
          song: const Song(id: '', title: '', sections: [], playOrder: []),
          starts: const [],
        ),
      );
      await tap(tester, save());
      expect(await copies(), isEmpty);
      expect(find.text(_l10n.contributeSubmitFixLyrics), findsOneWidget);
    });

    testWidgets('without a song on the phone it asks which one', (
      tester,
    ) async {
      await open(
        tester,
        auth: FakeAuthRepository(),
        draft: syncedDraft.copyWith(
          trackId: () => null,
          recording: () => null,
          starts: const [],
        ),
      );
      await tap(tester, save());
      expect(find.text(_l10n.contributeChooseSong), findsOneWidget);
      await tap(tester, find.text('Tizita'));

      final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
      final copy = (await copies()).single;
      expect(copy.trackId, tracks.single.id);
      expect(copy.timing, isNull);
      expect((await drafts(tester)).single.trackId, tracks.single.id);
    });

    testWidgets('closing the song list saves nothing', (tester) async {
      await open(tester, draft: syncedDraft.copyWith(trackId: () => null));
      await tap(tester, save());
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(await copies(), isEmpty);
      expect(contributions.calls, 0);
    });

    testWidgets('sending it later removes the saved copy', (tester) async {
      await open(tester);
      await tap(tester, save());
      await tap(tester, find.text('Selam'));
      // The "saved" message would cover Submit.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tap(tester, submit());
      final copy = (await copies()).single;
      expect(copy.contributionId, contributions.all.single.id);
    });

    testWidgets('deleting the draft removes the saved copy', (tester) async {
      await open(tester);
      await tap(tester, save());
      await tap(tester, find.byTooltip(_l10n.contributeDraftDelete));
      await tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_l10n.contributeDraftDelete),
        ),
      );
      expect(await drafts(tester), isEmpty);
      expect(await copies(), isEmpty);
    });
  });

  group('a guest sending', () {
    testWidgets('is asked to sign in; Not now sends nothing', (tester) async {
      await open(tester, auth: FakeAuthRepository());
      await tap(tester, submit());
      expect(find.text(_l10n.contributeSendSignInReason), findsOneWidget);
      await tap(tester, find.text(_l10n.signInPromptNotNow));
      expect(contributions.calls, 0);
      expect(await drafts(tester), hasLength(1));
    });

    testWidgets('who signs in sends it', (tester) async {
      await open(tester, auth: FakeAuthRepository());
      await tap(tester, submit());
      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));
      await tap(tester, find.text(_l10n.signInWithGoogle));
      expect(contributions.calls, 1);
      expect(await drafts(tester), isEmpty);
    });
  });

  group('Submit', () {
    testWidgets('sends one contribution, keeps an own copy, deletes the '
        'draft and goes back to S05 with a message', (tester) async {
      await open(tester);
      await tap(tester, submit());

      expect(contributions.sent, [syncedDraft.toContribution()]);
      expect(contributions.all.single.status, ContributionStatus.pending);
      expect(await drafts(tester), isEmpty);
      final copy = (await copies()).single;
      expect(copy.contributionId, contributions.all.single.id);
      expect(copy.kind, 'new_song');
      expect(copy.trackId, 7);
      expect(
        Song.fromJson(jsonDecode(copy.song)),
        syncedDraft.toContribution().song,
      );
      expect(
        SyncTiming.fromJson(jsonDecode(copy.timing!)).starts,
        syncedDraft.starts,
      );
      expect(Recording.fromJson(jsonDecode(copy.recording!)).id, 'rec-1');
      expect(find.byType(ContributeScreen), findsOneWidget);
      expect(find.text(_l10n.contributeSubmitSent), findsOneWidget);
    });

    testWidgets("keeps Zema's copy of a shared file until the review", (
      tester,
    ) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('review'),
      ))!;
      addTearDown(() => dir.delete(recursive: true));
      final audio = File('${dir.path}/shared_audio/1-Selam.ogg');
      await tester.runAsync(() => audio.create(recursive: true));
      await open(
        tester,
        draft: syncedDraft.copyWith(
          recording: () => const Recording(
            id: 'rec-1',
            songId: '',
            source: RecordingSource.telegram,
            fileName: 'Selam.ogg',
          ),
          trackId: () => null,
          audioPath: () => audio.path,
        ),
      );
      await tap(tester, submit());

      expect(await drafts(tester), isEmpty);
      expect((await copies()).single.audioPath, audio.path);
      expect(audio.existsSync(), isTrue);
    });

    testWidgets('runs the rules again: broken lyrics are not sent', (
      tester,
    ) async {
      await open(
        tester,
        draft: syncedDraft.copyWith(
          song: const Song(id: '', title: '', sections: [], playOrder: []),
          starts: const [],
        ),
      );
      await tap(tester, submit());
      expect(find.text(_l10n.contributeSubmitFixLyrics), findsOneWidget);
      expect(contributions.calls, 0, reason: 'checked on the phone first');
      expect(await drafts(tester), hasLength(1));
    });

    for (final (name, failure, message) in [
      (
        'offline',
        const NetworkFailure('offline') as ZemaFailure,
        _l10n.contributeSubmitOffline,
      ),
      (
        'a server error',
        const BackendFailure('500'),
        _l10n.contributeSubmitFailed,
      ),
      (
        'too many open',
        const ContributionFailure('limit', code: 'too_many_open'),
        _l10n.contributeSubmitTooManyOpen(maxOpenContributions),
      ),
      (
        'too many today',
        const ContributionFailure('limit', code: 'too_many_today'),
        _l10n.contributeSubmitTooManyToday(maxContributionsPerDay),
      ),
      (
        'signed out',
        const AuthFailure('not signed in'),
        _l10n.contributeSubmitSignIn,
      ),
    ]) {
      testWidgets('$name: the draft is kept, the message names it, and '
          'Submit can be tried again', (tester) async {
        await open(tester);
        contributions.failure = failure;
        await tap(tester, submit());

        expect(find.text(message), findsOneWidget);
        expect(find.byType(ReviewStep), findsOneWidget);
        expect(await drafts(tester), [syncedDraft]);
        expect(await copies(), isEmpty);
        expect(contributions.sent, isEmpty);

        await tap(tester, submit());
        expect(contributions.sent, hasLength(1));
        expect(await drafts(tester), isEmpty);
        expect(find.byType(ContributeScreen), findsOneWidget);
      });
    }

    test('the limits name their numbers', () {
      expect(
        _l10n.contributeSubmitTooManyOpen(maxOpenContributions),
        contains('20'),
      );
      expect(
        _l10n.contributeSubmitTooManyToday(maxContributionsPerDay),
        contains('30'),
      );
    });

    testWidgets('shows progress while sending and sends once', (tester) async {
      await open(tester);
      final gate = contributions.gate = Completer<void>();
      await tester.tap(submit());
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();
      expect(contributions.calls, 1);
      expect(contributions.sent, hasLength(1));
      expect(find.byType(ContributeScreen), findsOneWidget);
    });
  });

  group('a correction', () {
    const base = Song(
      id: 'selam',
      title: 'Selam',
      sections: [
        LyricSection(
          id: 'v1',
          kind: SectionKind.verse,
          lines: [LyricLine('one'), LyricLine('two')],
        ),
      ],
      playOrder: ['v1'],
    );
    const recording = Recording(
      id: 'rec-1',
      songId: 'selam',
      source: RecordingSource.localFile,
      artist: 'Sunday Choir',
      fileName: 'Selam.mp3',
    );
    final catalog = FakeCatalogRepository(
      lyrics: MemoryLyricsRepository(
        [base],
        recordings: [recording],
        timings: const [
          SyncTiming(
            recordingId: 'rec-1',
            starts: [Duration(seconds: 1), Duration(seconds: 2)],
          ),
        ],
      ),
    );

    ContributionDraft correction(Song song) => ContributionDraft(
      kind: ContributionKind.editLyrics,
      songId: 'selam',
      baseVersion: 1,
      song: song,
      step: DraftStep.review,
    );

    // From S05: the catalog index loads under the tabs.
    Future<void> openCorrection(WidgetTester tester, Song song) async {
      await open(
        tester,
        draft: correction(song),
        catalog: catalog,
        location: AppRoutes.contribute,
      );
      await tap(tester, find.text('Selam'));
    }

    testWidgets('with nothing changed, Submit is off', (tester) async {
      await openCorrection(tester, base);
      expect(find.text(_l10n.contributeCorrectionNoChanges), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _l10n.contributeSubmit),
            )
            .onPressed,
        isNull,
      );
      expect(find.text(_l10n.contributeCorrectionSuggest), findsOneWidget);
    });

    testWidgets('shows the changed lines and the recordings losing timings', (
      tester,
    ) async {
      await openCorrection(
        tester,
        const Song(
          id: 'selam',
          title: 'Selam',
          sections: [
            LyricSection(
              id: 'v1',
              kind: SectionKind.verse,
              lines: [LyricLine('one'), LyricLine('two'), LyricLine('three')],
            ),
          ],
          playOrder: ['v1'],
        ),
      );
      expect(find.byType(CorrectionChanges), findsOneWidget);
      expect(find.text(_l10n.contributeCorrectionLosesTimings), findsOneWidget);
      expect(find.textContaining('Sunday Choir'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _l10n.contributeSubmit),
            )
            .onPressed,
        isNotNull,
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
        draft: syncedDraft.copyWith(
          song: const Song(
            id: '',
            title: 'እግዚአብሔርን አመስግኑ ቸር ነውና ለዘላለም ምሕረቱ',
            artist: 'የቅዱስ ጊዮርጊስ ሰንበት ትምህርት ቤት መዘምራን',
            sections: [
              LyricSection(
                id: 'v1',
                kind: SectionKind.verse,
                lines: [LyricLine('እግዚአብሔርን አመስግኑ ቸር ነውና ለዘላለም ምሕረቱ')],
              ),
            ],
            playOrder: ['v1', 'v1'],
          ),
          starts: [s(1), s(5)],
        ),
      );
      expect(tester.takeException(), isNull);
      contributions.failure = const ContributionFailure(
        'limit',
        code: 'too_many_open',
      );
      await tap(tester, submit());
      expect(
        find.text(_l10n.contributeSubmitTooManyOpen(maxOpenContributions)),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(_l10n.contributeReviewSynced),
        200,
        scrollable: find.descendant(
          of: find.byType(ReviewStep),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
