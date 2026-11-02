import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/features/contribute/presentation/recording_step.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_catalog.dart';
import '../../helpers/fake_library.dart';
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
    LyricSection(
      id: 'c1',
      kind: SectionKind.chorus,
      lines: [LyricLine('Haleluya')],
    ),
  ],
  playOrder: ['v1', 'c1', 'c1'],
);

const kidus = Song(
  id: 'kidus',
  title: 'Kidus',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('Kidus kidus')],
    ),
  ],
  playOrder: ['v1'],
);

void main() {
  late ZemaDatabase db;
  late FakeCatalogRepository catalog;

  setUp(() {
    db = memoryDatabase();
    catalog = FakeCatalogRepository(
      lyrics: MemoryLyricsRepository([selam, kidus]),
    )..versions[selam.id] = 5;
  });

  Future<void> open(
    WidgetTester tester, {
    ContributionDraft draft = const ContributionDraft(),
    Size size = const Size(400, 1600),
    double textScale = 1,
    Brightness brightness = Brightness.dark,
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    // The phone's copy of the index (the shell's start-up refresh fills it;
    // the flow opens outside the shell). None when offline from the start.
    if (catalog.failure == null) {
      await db.catalogDao.replaceAll(await catalog.index());
    }
    final id = await db.draftsDao.create(draft, now: DateTime.utc(2026, 11, 2));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: AppRoutes.draft(id),
      auth: FakeAuthRepository(user: testUser),
      database: db,
      catalog: catalog,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
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

  Finder titleField() =>
      find.widgetWithText(TextField, _l10n.contributeFieldTitle);

  Finder warning() => find.text(_l10n.contributeSimilarTitle);

  Future<void> typeTitle(WidgetTester tester, String title) async {
    await tester.enterText(titleField(), title);
    await tester.pump(similarSongDelay);
    await tester.pumpAndSettle();
  }

  testWidgets('a title like a catalog song shows it after a pause', (
    tester,
  ) async {
    await open(tester);
    expect(warning(), findsNothing);

    await tester.enterText(titleField(), 'Selam lezi');
    await tester.pump(similarSongDelay - const Duration(milliseconds: 100));
    expect(warning(), findsNothing, reason: 'still typing');
    await tester.pump(const Duration(milliseconds: 100));
    expect(warning(), findsOneWidget);
    expect(find.text('Selam Lezih Bet'), findsOneWidget);
    expect(find.text('Choir'), findsOneWidget);
    expect(find.text('Kidus'), findsNothing);

    // Typing on starts the wait again; an unlike title clears it.
    await tester.enterText(titleField(), 'Mezmur zelealem');
    await tester.pump(const Duration(milliseconds: 100));
    expect(warning(), findsOneWidget);
    await tester.pump(similarSongDelay);
    expect(warning(), findsNothing);
  });

  testWidgets('Add a recording turns the draft into a recording of that '
      'song, at S20', (tester) async {
    await open(tester);
    await typeTitle(tester, 'Selam Lezih');
    await tap(tester, find.text(_l10n.contributeSimilarAddRecording));

    expect(find.byType(RecordingStep), findsOneWidget);
    final draft = await saved(tester);
    expect(draft.kind, ContributionKind.recording);
    expect(draft.songId, selam.id);
    expect(draft.song, selam);
    expect(draft.step, DraftStep.recording);
  });

  testWidgets('Suggest a correction fills S19 with the catalog song', (
    tester,
  ) async {
    await open(tester);
    await typeTitle(tester, 'Selam Lezih');
    await tap(tester, find.text(_l10n.contributeSimilarCorrect));

    expect(find.byType(LyricsStep), findsOneWidget);
    expect(find.text(_l10n.contributeCorrectionNote), findsOneWidget);
    expect(warning(), findsNothing);
    expect(
      tester.widget<TextField>(titleField()).controller!.text,
      'Selam Lezih Bet',
    );
    expect(find.text('Selam lezih bet\nSelam lekulu'), findsOneWidget);
    final draft = await saved(tester);
    expect(draft.kind, ContributionKind.editLyrics);
    expect(draft.songId, selam.id);
    expect(draft.baseVersion, 5);
    expect(draft.song, selam);
    final contribution = draft.toContribution();
    expect(contribution.kind.wire, 'edit_lyrics');
    expect(contribution.baseVersion, 5);

    // A correction has no recording: Next goes to review.
    await tap(
      tester,
      find.widgetWithText(FilledButton, _l10n.contributeNextReview),
    );
    expect((await saved(tester)).step, DraftStep.review);
  });

  testWidgets('Not the same song hides it, and it stays hidden', (
    tester,
  ) async {
    await open(tester);
    await typeTitle(tester, 'Selam Lezih');
    await tap(tester, find.byTooltip(_l10n.contributeSimilarIgnore));
    expect(warning(), findsNothing);
    await typeTitle(tester, 'Selam Lezih Bet');
    expect(warning(), findsNothing);
    expect((await saved(tester)).kind, ContributionKind.newSong);
  });

  testWidgets('a title filled in before is checked when S19 opens', (
    tester,
  ) async {
    await open(
      tester,
      draft: const ContributionDraft(
        song: Song(id: '', title: 'Kidus', sections: []),
      ),
    );
    await tester.pump(similarSongDelay);
    await tester.pumpAndSettle();
    expect(warning(), findsOneWidget);
  });

  testWidgets('a correction never looks for similar songs', (tester) async {
    await open(tester, draft: correctionDraft(kidus, baseVersion: 1));
    await typeTitle(tester, 'Selam Lezih');
    expect(warning(), findsNothing);
  });

  testWidgets('offline with no index, it is skipped quietly', (tester) async {
    catalog.failure = const NetworkFailure('offline');
    await open(tester);
    await typeTitle(tester, 'Selam Lezih');
    expect(warning(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a song that can\'t be downloaded says so and changes nothing', (
    tester,
  ) async {
    await open(tester);
    await typeTitle(tester, 'Selam Lezih');
    catalog.failure = const NetworkFailure('offline');
    await tap(tester, find.text(_l10n.contributeSimilarCorrect));
    expect(find.text(_l10n.contributeSimilarUnavailable), findsOneWidget);
    expect((await saved(tester)).kind, ContributionKind.newSong);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the warning fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      await open(
        tester,
        size: const Size(360, 640),
        textScale: 1.3,
        brightness: brightness,
      );
      await typeTitle(tester, 'Selam Lezih');
      expect(warning(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(_l10n.contributeSimilarCorrect),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
