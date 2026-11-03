import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/widgets/sign_in_prompt.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/data/shared_audio.dart';
import 'package:zema/features/contribute/data/youtube_info.dart';
import 'package:zema/features/contribute/presentation/contribute_flow_screen.dart';
import 'package:zema/features/contribute/presentation/recording_step.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_contribute.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

const videoId = 'dQw4w9WgXcQ';

const lyrics = Song(
  id: '',
  title: 'Selam',
  sections: [
    LyricSection(id: 'v1', kind: SectionKind.verse, lines: [LyricLine('a')]),
  ],
  playOrder: ['v1'],
);

void main() {
  late ZemaDatabase db;
  late FakeAuthRepository auth;
  late FakeYoutubeInfoService youtube;
  late FakeShareReceiver shares;
  late Directory temp;

  setUp(() {
    db = memoryDatabase();
    auth = FakeAuthRepository(user: testUser);
    youtube = FakeYoutubeInfoService({
      videoId: YoutubeInfo(
        title: 'Selam (live)',
        author: 'Sunday School Choir',
        thumbnail: testThumbnail,
      ),
    });
    shares = FakeShareReceiver();
    temp = Directory.systemTemp.createTempSync('zema_share');
    addTearDown(() => temp.deleteSync(recursive: true));
  });

  /// A file as `ShareChannel` leaves it: `shared_audio/<millis>-<name>`.
  SharedAudio sharedFile(String name) {
    final folder = Directory(p.join(temp.path, 'shared_audio'))
      ..createSync(recursive: true);
    final file = File(p.join(folder.path, '1700000000000-$name'))
      ..writeAsBytesSync([1, 2, 3]);
    return SharedAudio(
      path: file.path,
      name: name,
      duration: const Duration(minutes: 3, seconds: 20),
    );
  }

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.contribute,
    bool backendConfigured = true,
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    Size size = const Size(400, 1600),
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
      backendConfigured: backendConfigured,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
      youtube: youtube,
      shareReceiver: shares,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(
          1,
          '/music/Tizita.mp3',
          title: 'Tizita',
          artist: 'Mulatu',
          durationMs: 245000,
        ),
        scannedAudio(2, '/music/Selam.m4a', title: 'Selam', artist: 'Choir'),
      ]),
    );
  }

  Future<int> openDraft(
    WidgetTester tester, {
    ContributionDraft draft = const ContributionDraft(
      song: lyrics,
      step: DraftStep.recording,
    ),
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) async {
    final id = await db.draftsDao.create(draft, now: DateTime.utc(2026, 11, 2));
    await start(
      tester,
      location: AppRoutes.draft(id),
      brightness: brightness,
      textScale: textScale,
      size: size,
    );
    return id;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<List<ContributionDraft>> savedDrafts(WidgetTester tester) async {
    await tester.pump(draftSaveDelay * 2);
    return [
      for (final row in await db.select(db.drafts).get())
        ContributionDraft.fromJson(jsonDecode(row.draft)),
    ];
  }

  Future<ContributionDraft> saved(WidgetTester tester) async =>
      (await savedDrafts(tester)).single;

  Future<int> trackId(String title) async =>
      (await db.select(db.tracks).get()).firstWhere((t) => t.title == title).id;

  Finder next(String label) => find.widgetWithText(FilledButton, label);

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(next(label)).onPressed != null;

  Finder field(String label) => find.widgetWithText(TextField, label);

  /// Lets real file work (deleting a shared copy) finish.
  Future<void> settleFiles(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a song on the phone: searched, picked, its file and length '
      'kept, the artist filled in', (tester) async {
    await openDraft(tester);
    expect(enabled(tester, _l10n.contributeNextSync), isFalse);

    await tap(tester, find.text(_l10n.contributeRecordingLocal));
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      'tiz',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Selam'),
      ),
      findsNothing,
    );
    await tap(tester, find.text('Tizita'));

    final draft = await saved(tester);
    expect(draft.recording?.source, RecordingSource.localFile);
    expect(draft.recording?.fileName, 'Tizita.mp3');
    expect(draft.recording?.duration, const Duration(seconds: 245));
    expect(draft.recording?.artist, 'Mulatu');
    expect(draft.trackId, await trackId('Tizita'));
    expect(
      tester
          .widget<TextField>(field(_l10n.contributeRecordingArtist))
          .controller!
          .text,
      'Mulatu',
    );
    expect(find.text('Tizita.mp3 · 4:05'), findsOneWidget);

    await tap(tester, next(_l10n.contributeNextSync));
    expect((await saved(tester)).step, DraftStep.sync);
  });

  testWidgets('the track that opened the flow is marked in the picker', (
    tester,
  ) async {
    await start(tester);
    final id = await trackId('Selam');
    await tester.pumpWidget(const SizedBox());
    await openDraft(
      tester,
      draft: ContributionDraft(
        song: lyrics,
        trackId: id,
        step: DraftStep.recording,
      ),
    );
    await tap(tester, find.text(_l10n.contributeRecordingLocal));
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Selam').last,
          matching: find.byType(Semantics),
        ),
        matching: find.byIcon(Icons.check),
      ),
      findsWidgets,
    );
  });

  testWidgets('a YouTube link: looked up, the channel fills the artist, and '
      'syncing is skipped', (tester) async {
    await openDraft(tester);
    await tap(tester, find.text(_l10n.contributeRecordingYoutube));
    expect(find.text(_l10n.contributeYoutubeNoSync), findsOneWidget);

    await tester.enterText(
      field(_l10n.contributeYoutubeLink),
      'https://www.youtube.com/playlist?list=PL123',
    );
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contributeYoutubeBadLink), findsOneWidget);
    expect(enabled(tester, _l10n.contributeNextSync), isFalse);

    await tester.enterText(
      field(_l10n.contributeYoutubeLink),
      'https://youtu.be/$videoId?si=abc',
    );
    await tester.pumpAndSettle();
    expect(find.text('Selam (live)'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    final draft = await saved(tester);
    expect(draft.recording?.source, RecordingSource.youtube);
    expect(draft.recording?.youtubeId, videoId);
    expect(draft.recording?.artist, 'Sunday School Choir');
    expect(draft.videoTitle, 'Selam (live)');

    await tap(tester, next(_l10n.contributeNextReview));
    expect((await saved(tester)).step, DraftStep.review);
  });

  testWidgets('offline, the video keeps its id and the title is typed; the '
      'length must read', (tester) async {
    youtube = FakeYoutubeInfoService();
    await openDraft(tester);
    await tap(tester, find.text(_l10n.contributeRecordingYoutube));
    await tester.enterText(field(_l10n.contributeYoutubeLink), videoId);
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contributeYoutubeOffline), findsOneWidget);

    await tester.enterText(field(_l10n.contributeYoutubeTitle), 'Selam live');
    await tester.enterText(field(_l10n.contributeYoutubeDuration), '4:5');
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contributeYoutubeBadDuration), findsOneWidget);
    expect(enabled(tester, _l10n.contributeNextReview), isFalse);

    await tester.enterText(field(_l10n.contributeYoutubeDuration), '4:05');
    await tester.pumpAndSettle();
    expect(enabled(tester, _l10n.contributeNextReview), isTrue);
    final draft = await saved(tester);
    expect(draft.recording?.youtubeId, videoId);
    expect(draft.recording?.duration, const Duration(minutes: 4, seconds: 5));
    expect(draft.videoTitle, 'Selam live');
  });

  testWidgets('a new song can skip the recording, even one chosen', (
    tester,
  ) async {
    await openDraft(tester);
    await tap(tester, find.text(_l10n.contributeRecordingLocal));
    await tap(tester, find.text('Tizita'));
    expect((await saved(tester)).recording, isNotNull);
    await tap(tester, find.text(_l10n.contributeSkipRecording));
    final draft = await saved(tester);
    expect(draft.recording, isNull);
    expect(draft.step, DraftStep.review);
  });

  testWidgets('a correction has no Skip', (tester) async {
    await openDraft(
      tester,
      draft: const ContributionDraft(
        kind: ContributionKind.recording,
        songId: 'selam',
        song: lyrics,
        step: DraftStep.recording,
      ),
    );
    expect(find.text(_l10n.contributeSkipRecording), findsNothing);
  });

  testWidgets('Next with lyrics still to fix goes back to them', (
    tester,
  ) async {
    await openDraft(
      tester,
      draft: const ContributionDraft(step: DraftStep.recording),
    );
    await tap(tester, find.text(_l10n.contributeRecordingLocal));
    await tap(tester, find.text('Tizita'));
    await tap(tester, next(_l10n.contributeNextSync));
    expect(find.text(_l10n.contributeLyricsFirst), findsOneWidget);
    expect((await saved(tester)).step, DraftStep.lyrics);
  });

  testWidgets('Back and the step strip go to the lyrics', (tester) async {
    await openDraft(tester);
    await tap(tester, find.text(_l10n.contributeBack));
    expect((await saved(tester)).step, DraftStep.lyrics);
    await tap(tester, next(_l10n.contributeNextRecording));
    expect(find.byType(RecordingStep), findsOneWidget);

    await tap(
      tester,
      find.descendant(
        of: find.byType(StepStrip),
        matching: find.text(_l10n.contributeStepLyrics),
      ),
    );
    expect((await saved(tester)).step, DraftStep.lyrics);
  });

  group('shared audio', () {
    testWidgets('the file that started the app opens S20 with it chosen', (
      tester,
    ) async {
      final audio = sharedFile('Selam choir.ogg');
      shares.initial = audio;
      await start(tester, location: AppRoutes.home);

      expect(find.byType(RecordingStep), findsOneWidget);
      expect(find.text('Selam choir.ogg'), findsOneWidget);
      final draft = await saved(tester);
      expect(draft.audioPath, audio.path);
      expect(draft.recording?.source, RecordingSource.telegram);
      expect(draft.recording?.fileName, 'Selam choir.ogg');
      expect(draft.recording?.duration, audio.duration);
      expect(draft.step, DraftStep.recording);
      expect(sharedFileName(audio.path), 'Selam choir.ogg');
    });

    testWidgets('a file shared while the app runs does too', (tester) async {
      await start(tester);
      shares.share(sharedFile('Tizita.mp3'));
      await tester.pumpAndSettle();
      expect(find.byType(ContributeFlowScreen), findsOneWidget);
      expect(find.text('Tizita.mp3'), findsOneWidget);
    });

    testWidgets('a guest goes on to S20 without signing in', (tester) async {
      auth = FakeAuthRepository();
      await start(tester);
      shares.share(sharedFile('Selam.ogg'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPrompt), findsNothing);
      expect(find.byType(RecordingStep), findsOneWidget);
    });

    testWidgets('without a backend it says so and keeps nothing', (
      tester,
    ) async {
      final audio = sharedFile('Selam.ogg');
      await start(tester, backendConfigured: false);
      shares.share(audio);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(_l10n.contributeShareNeedsBackend),
        ),
        findsOneWidget,
      );
      await settleFiles(tester);
      expect(File(audio.path).existsSync(), isFalse);
    });

    testWidgets('deleting the draft deletes the copy', (tester) async {
      final audio = sharedFile('Selam.ogg');
      await db.draftsDao.create(
        ContributionDraft(
          song: lyrics,
          audioPath: audio.path,
          step: DraftStep.recording,
        ),
        now: DateTime.utc(2026, 11, 2),
      );
      await start(tester);
      await tap(tester, find.byTooltip(_l10n.contributeDraftDelete));
      await tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_l10n.contributeDraftDelete),
        ),
      );
      await settleFiles(tester);
      expect(File(audio.path).existsSync(), isFalse);
    });

    testWidgets("signing out keeps a draft's copy", (tester) async {
      final audio = sharedFile('Selam.ogg');
      await db.draftsDao.create(
        ContributionDraft(audioPath: audio.path),
        now: DateTime.utc(2026, 11, 2),
      );
      await start(tester, location: AppRoutes.profile);
      await tap(tester, find.text(_l10n.profileSignOut));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_l10n.profileSignOut),
        ),
      );
      await settleFiles(tester);
      expect(File(audio.path).existsSync(), isTrue);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      await openDraft(
        tester,
        brightness: brightness,
        textScale: 1.3,
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
      await tap(tester, find.text(_l10n.contributeRecordingYoutube));
      await tester.enterText(field(_l10n.contributeYoutubeLink), videoId);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        field(_l10n.contributeYoutubeDuration),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tap(tester, find.text(_l10n.contributeRecordingLocal));
      expect(tester.takeException(), isNull);
    });
  }
}
