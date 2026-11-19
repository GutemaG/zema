import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/application/my_contributions.dart';
import 'package:zema/features/contribute/data/contribution_seen.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/features/contribute/presentation/my_contributions_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_catalog.dart';
import '../../helpers/fake_contribute.dart';
import '../../helpers/fake_contributions.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

Song song(String title) => Song(
  id: '',
  title: title,
  sections: const [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('One'), LyricLine('Two')],
    ),
  ],
  playOrder: const ['v1'],
);

const recording = Recording(
  id: 'rec-1',
  songId: '',
  source: RecordingSource.localFile,
  duration: Duration(minutes: 3),
  fileName: 'Selam.mp3',
);

Contribution newSong(String title, {bool synced = false}) => ContributionDraft(
  song: song(title),
  recording: synced ? recording : null,
  starts: synced
      ? const [Duration(seconds: 1), Duration(seconds: 2)]
      : const [],
).toContribution();

/// Offline while [offline] is set.
class _Contributions extends FakeContributionRepository {
  bool offline = false;

  @override
  Future<List<SubmittedContribution>> mine() async {
    if (offline) throw const NetworkFailure('offline');
    return super.mine();
  }

  /// A moderator decides on [id].
  Future<void> decide(
    String id,
    ReviewDecision decision, [
    String? note,
  ]) async {
    final me = userId;
    userId = 'moderator';
    moderator = true;
    try {
      await review(id, decision, note: note);
    } finally {
      userId = me;
      moderator = false;
    }
  }
}

void main() {
  late ZemaDatabase db;
  late _Contributions contributions;
  late FakeCatalogRepository catalog;

  setUp(() {
    db = memoryDatabase();
    contributions = _Contributions();
    catalog = FakeCatalogRepository(entries: const []);
  });

  Future<void> open(WidgetTester tester, String location) async {
    useScreen(tester, size: const Size(400, 1000));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: location,
      auth: FakeAuthRepository(user: testUser),
      database: db,
      googlePicker: FakeGoogleAccountPicker(),
      savedPrefs: {AccountChoiceController.key: true},
      syncPlayer: FakeSyncPlayer(),
      contributions: contributions,
      catalog: catalog,
    );
    await tester.pumpAndSettle();
  }

  Future<void> check(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    unawaited(container.read(myContributionsProvider.notifier).check());
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('a review since the last check: a message, the badge, the '
      'own copy applied; opening S23 clears the badge', (tester) async {
    final old = await contributions.submit(newSong('Old'));
    await contributions.decide(old, ReviewDecision.approve);
    final id = await contributions.submit(newSong('Selam'));
    await db.ownCopiesDao.add(
      OwnCopy(
        contributionId: id,
        kind: ContributionKind.newSong,
        song: song('Selam'),
        trackId: 3,
        submittedAt: DateTime.utc(2026, 11, 2),
      ),
    );
    await open(tester, AppRoutes.home);
    expect(find.byType(SnackBar), findsNothing, reason: 'first check');
    expect(find.byType(Badge), findsNothing);
    expect(await db.select(db.ownCopies).get(), hasLength(1));

    final fetched = catalog.indexCalls;
    await contributions.decide(id, ReviewDecision.approve);
    await check(tester);
    expect(
      find.text(_l10n.contributionApprovedMessage('Selam')),
      findsOneWidget,
    );
    expect(
      catalog.indexCalls,
      fetched + 1,
      reason: 'the song index is fetched at once, for the new song',
    );
    expect(find.byType(Badge), findsOneWidget);
    expect(
      await db.select(db.ownCopies).get(),
      isEmpty,
      reason: 'the track shows the catalog version now',
    );

    await check(tester);

    await tap(tester, find.text(_l10n.actionView));
    expect(find.byType(MyContributionsScreen), findsOneWidget);
    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'told once, though checked twice',
    );
    await tap(tester, find.text(_l10n.myContributionsApproved));
    expect(find.text('Selam'), findsOneWidget);
    expect(find.text('Old'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('offline: no badge change, and S23 offers to try again', (
    tester,
  ) async {
    final id = await contributions.submit(newSong('Selam'));
    contributions.offline = true;
    await open(tester, AppRoutes.home);
    await contributions.decide(id, ReviewDecision.reject, 'Duplicate');
    await check(tester);
    expect(find.byType(Badge), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await open(tester, AppRoutes.myContributions);
    expect(find.text(_l10n.myContributionsOffline), findsOneWidget);
    contributions.offline = false;
    await tap(tester, find.text(_l10n.actionTryAgain));
    await tap(tester, find.text(_l10n.myContributionsRejected));
    expect(find.text('Selam'), findsOneWidget);
    expect(find.text(_l10n.myContributionsReason('Duplicate')), findsOneWidget);
  });

  testWidgets('tabs list cards with kind, date and comment', (tester) async {
    await contributions.submit(newSong('Waiting'));
    final sent = await contributions.submit(newSong('Back'));
    await contributions.decide(
      sent,
      ReviewDecision.requestChanges,
      'Fix line two',
    );
    await open(tester, AppRoutes.myContributions);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
    expect(find.textContaining(_l10n.contributionKindNewSong), findsOneWidget);
    await tap(tester, find.text(_l10n.myContributionsNeedsChanges));
    expect(find.text('Back'), findsOneWidget);
    expect(
      find.text(_l10n.myContributionsComment('Fix line two')),
      findsOneWidget,
    );
    expect(find.text(_l10n.myContributionsEdit), findsOneWidget);
    await tap(tester, find.text(_l10n.myContributionsApproved));
    expect(find.text(_l10n.myContributionsEmpty), findsOneWidget);
  });

  testWidgets('Edit and resend opens one draft with what was sent', (
    tester,
  ) async {
    final id = await contributions.submit(newSong('Back'));
    await contributions.decide(id, ReviewDecision.requestChanges, 'Fix');
    await open(tester, AppRoutes.myContributions);
    await tap(tester, find.text(_l10n.myContributionsNeedsChanges));
    await tap(tester, find.text(_l10n.myContributionsEdit));
    expect(find.byType(LyricsStep), findsOneWidget);
    await tap(tester, find.byType(CloseButton));
    await tap(tester, find.text(_l10n.myContributionsEdit));
    expect(find.byType(LyricsStep), findsOneWidget);
    await tester.pump(draftSaveDelay * 2);
    final rows = await db.select(db.drafts).get();
    expect(rows, hasLength(1), reason: 'the same draft again');
    final draft = ContributionDraft.fromJson(jsonDecode(rows.single.draft));
    expect(draft.resubmitId, id);
    expect(draft.title, 'Back');
  });

  testWidgets('Submit sends the same contribution again', (tester) async {
    final id = await contributions.submit(newSong('Back'));
    await contributions.decide(id, ReviewDecision.requestChanges, 'Fix');
    final draft = resubmitDraft(contributions.all.single)
        .copyWith(step: DraftStep.review);
    final draftId = await db.draftsDao.create(draft, now: DateTime.utc(2026));
    await open(tester, AppRoutes.draft(draftId));
    await tap(
      tester,
      find.widgetWithText(FilledButton, _l10n.contributeSubmit),
    );
    final all = contributions.all;
    expect(all, hasLength(1));
    expect(all.single.status, ContributionStatus.pending);
    expect(all.single.revision, 2);
    expect(await db.select(db.drafts).get(), isEmpty);
    expect((await db.select(db.ownCopies).get()).single.contributionId, id);
  });

  testWidgets('Profile shows lyrics added, synced and approved', (
    tester,
  ) async {
    final a = await contributions.submit(newSong('A', synced: true));
    await contributions.decide(a, ReviewDecision.approve);
    await contributions.submit(newSong('B'));
    final c = await contributions.submit(newSong('C', synced: true));
    await contributions.decide(c, ReviewDecision.reject, 'Duplicate');
    await open(tester, AppRoutes.profile);
    Finder stat(String count, String label) => find.ancestor(
      of: find.text(count),
      matching: find.ancestor(
        of: find.text(label),
        matching: find.byType(Column),
      ),
    );
    expect(stat('2', _l10n.profileStatLyrics), findsOneWidget);
    expect(stat('1', _l10n.profileStatSynced), findsOneWidget);
    expect(stat('1', _l10n.profileStatApproved), findsOneWidget);
  });

  test('the seen state survives a round trip and ignores junk', () {
    final seen = ContributionSeen(
      reviewedUntil: DateTime.utc(2026, 11, 2, 9),
      unseen: const {'a', 'b'},
    );
    expect(ContributionSeen.fromJson(seen.toJson()), seen);
    expect(
      ContributionSeen.fromJson({
        'reviewedUntil': 'soon',
        'unseen': [1, 'a'],
      }),
      const ContributionSeen(unseen: {'a'}),
    );
  });
}
