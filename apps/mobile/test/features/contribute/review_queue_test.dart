import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/review_item_screen.dart';
import 'package:zema/features/contribute/presentation/review_queue_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_contribute.dart';
import '../../helpers/fake_contributions.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

Song song(String id, String title, List<String> lines) => Song(
  id: id,
  title: title,
  artist: 'Abebe Choir',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [for (final l in lines) LyricLine(l)],
    ),
  ],
  playOrder: const ['v1'],
);

const catalogRecording = Recording(
  id: 'rec-1',
  songId: 'selam',
  source: RecordingSource.localFile,
  duration: Duration(minutes: 3),
  fileName: 'Selam.mp3',
);

final catalogSelam = SongDocument(
  song: song('selam', 'Selam', ['Line one', 'Line two']),
  recordings: const [catalogRecording],
);

/// The catalog's songs are at version [version] in the queue.
class _Contributions extends FakeContributionRepository {
  _Contributions() : super(moderator: true);

  int version = 1;

  @override
  Future<List<QueuedContribution>> queue({ContributionKind? kind}) async => [
    for (final q in await super.queue(kind: kind))
      QueuedContribution(
        id: q.id,
        contribution: q.contribution,
        submittedAt: q.submittedAt,
        revision: q.revision,
        authorName: q.authorName,
        previousNote: q.previousNote,
        currentVersion: q.currentVersion == null ? null : version,
        currentSong: q.currentSong,
      ),
  ];
}

void main() {
  late ZemaDatabase db;
  late _Contributions contributions;
  late List<Uri> opened;

  setUp(() {
    db = memoryDatabase();
    contributions = _Contributions();
    contributions.songs['selam'] = catalogSelam;
    opened = [];
  });

  /// Someone else sends [c]; returns its id.
  Future<String> other(Contribution c) async {
    contributions.userId = 'someone-else';
    try {
      return await contributions.submit(c);
    } finally {
      contributions.userId = testUser.id;
    }
  }

  Future<void> open(
    WidgetTester tester,
    String location, {
    bool moderator = true,
  }) async {
    useScreen(tester, size: const Size(400, 1000));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    final auth = FakeAuthRepository(user: testUser);
    await pumpZemaApp(
      tester,
      location: location,
      auth: auth,
      profiles: FakeProfileRepository(
        auth,
        profile: Profile(
          userId: testUser.id,
          displayName: 'Abebe',
          roles: {
            AccountRole.contributor,
            if (moderator) AccountRole.moderator,
          },
        ),
      ),
      database: db,
      googlePicker: FakeGoogleAccountPicker(),
      savedPrefs: {AccountChoiceController.key: true},
      syncPlayer: FakeSyncPlayer(),
      contributions: contributions,
      openUrl: (url) async {
        opened.add(url);
        return true;
      },
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Contribution newSong(String title) => Contribution.newSong(
    song(proposeSongSlug(title), title, ['First line', 'Second line']),
  );

  testWidgets('only moderators see the queue, from S05 and Profile', (
    tester,
  ) async {
    await open(tester, AppRoutes.contribute, moderator: false);
    expect(find.text(_l10n.reviewQueueTitle), findsNothing);
    await tester.pumpWidget(const SizedBox());

    await open(tester, AppRoutes.contribute);
    await tap(tester, find.text(_l10n.reviewQueueTitle));
    expect(find.byType(ReviewQueueScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await open(tester, AppRoutes.profile);
    expect(find.text(_l10n.profileRoleModerator), findsOneWidget);
    expect(find.text(_l10n.reviewQueueTitle), findsOneWidget);
  });

  testWidgets('the queue: oldest first, a count, a kind filter, the own '
      'hidden, an empty state', (tester) async {
    await other(newSong('First'));
    await other(
      Contribution.editLyrics(
        songId: 'selam',
        baseVersion: 1,
        song: song('selam', 'Selam', ['Line one', 'Line 2']),
      ),
    );
    await contributions.submit(newSong('Mine'));
    await open(tester, AppRoutes.reviewQueue);
    expect(find.text(_l10n.reviewQueueCount(2)), findsOneWidget);
    expect(find.text('Mine'), findsNothing);
    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Selam')).dy),
    );
    await tap(
      tester,
      find.widgetWithText(ChoiceChip, _l10n.contributionKindCorrection),
    );
    expect(find.text('First'), findsNothing);
    expect(find.text(_l10n.reviewQueueCount(1)), findsOneWidget);
    await tap(
      tester,
      find.widgetWithText(ChoiceChip, _l10n.contributionKindSync),
    );
    expect(find.text(_l10n.reviewQueueEmpty), findsOneWidget);
  });

  testWidgets('a new song shows its lyrics; Approve takes it out', (
    tester,
  ) async {
    await other(newSong('First'));
    await open(tester, AppRoutes.reviewQueue);
    await tap(tester, find.text('First'));
    expect(find.byType(ReviewItemScreen), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
    expect(find.text(_l10n.reviewCheckLyrics), findsOneWidget);
    await tap(tester, find.text(_l10n.reviewApprove));
    expect(find.text(_l10n.reviewApproved), findsOneWidget);
    expect(find.byType(ReviewQueueScreen), findsOneWidget);
    expect(find.text('First'), findsNothing);
    expect(contributions.all.single.status, ContributionStatus.approved);
  });

  testWidgets('Request changes and Reject need a comment', (tester) async {
    final a = await other(newSong('First'));
    final b = await other(newSong('Second'));
    await open(tester, AppRoutes.reviewItem(a));
    await tap(tester, find.text(_l10n.reviewRequestChanges));
    Finder send() => find.widgetWithText(TextButton, _l10n.reviewSend);
    expect(tester.widget<TextButton>(send()).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<TextButton>(send()).onPressed, isNull);
    await tester.enterText(find.byType(TextField), ' Fix line two ');
    await tester.pump();
    await tap(tester, send());
    expect(find.text(_l10n.reviewChangesRequested), findsOneWidget);
    final first = contributions.all.firstWhere((c) => c.id == a);
    expect(first.status, ContributionStatus.changesRequested);
    expect(first.reviewNote, 'Fix line two');

    await tap(tester, find.text('Second'));
    await tap(tester, find.text(_l10n.reviewReject));
    await tap(tester, find.text(_l10n.actionCancel));
    expect(
      contributions.all.firstWhere((c) => c.id == b).status,
      ContributionStatus.pending,
      reason: 'cancelled',
    );
  });

  testWidgets('a correction shows its changes, flagged when based on an '
      'older version', (tester) async {
    final id = await other(
      Contribution.editLyrics(
        songId: 'selam',
        baseVersion: 1,
        song: song('selam', 'Selam', ['Line one', 'Line 2']),
      ),
    );
    await open(tester, AppRoutes.reviewItem(id));
    expect(find.text('Line 2'), findsWidgets);
    expect(find.text(_l10n.reviewItemOlderVersion), findsNothing);
    contributions.version = 2;
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await open(tester, AppRoutes.reviewItem(id));
    expect(
      find.text(_l10n.contributeCorrectionChanges.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_l10n.reviewItemOlderVersion), findsOneWidget);
  });

  testWidgets('a YouTube recording opens in YouTube', (tester) async {
    final id = await other(
      const Contribution.recording(
        songId: 'selam',
        recording: Recording(
          id: 'rec-2',
          songId: 'selam',
          source: RecordingSource.youtube,
          youtubeId: 'dQw4w9WgXcQ',
        ),
      ),
    );
    await open(tester, AppRoutes.reviewItem(id));
    expect(find.text(_l10n.reviewItemYoutube), findsOneWidget);
    expect(
      find.text('Line two'),
      findsOneWidget,
      reason: "the catalog's lyrics",
    );
    await tap(tester, find.text(_l10n.reviewItemOpenYoutube));
    expect(opened.single.queryParameters['v'], 'dQw4w9WgXcQ');
  });

  testWidgets('a timing previews silently, lighting each line up', (
    tester,
  ) async {
    final id = await other(
      const Contribution.syncTiming(
        songId: 'selam',
        timing: SyncTiming(
          recordingId: 'rec-1',
          starts: [Duration(seconds: 1), Duration(seconds: 2)],
        ),
      ),
    );
    await open(tester, AppRoutes.reviewItem(id));
    expect(find.text('Selam.mp3'), findsOneWidget);
    FontWeight? weight(String line) =>
        tester.widget<Text>(find.text(line)).style?.fontWeight;
    expect(weight('Line one'), isNot(FontWeight.w600));
    await tap(tester, find.text(_l10n.reviewItemPreview));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(weight('Line one'), FontWeight.w600);
    expect(weight('Line two'), isNot(FontWeight.w600));
    await tester.pump(const Duration(seconds: 1));
    expect(weight('Line two'), FontWeight.w600);
    expect(weight('Line one'), isNot(FontWeight.w600));
    await tap(tester, find.text(_l10n.reviewItemStop));
    expect(weight('Line two'), isNot(FontWeight.w600));
  });

  testWidgets('reviewed by someone else first: a message, the queue '
      'refreshed', (tester) async {
    final id = await other(newSong('First'));
    await open(tester, AppRoutes.reviewQueue);
    await tap(tester, find.text('First'));
    contributions.userId = 'another-moderator';
    await contributions.review(id, ReviewDecision.approve);
    contributions.userId = testUser.id;
    await tap(tester, find.text(_l10n.reviewApprove));
    expect(find.text(_l10n.reviewAlreadyReviewed), findsOneWidget);
    expect(find.byType(ReviewQueueScreen), findsOneWidget);
    expect(find.text('First'), findsNothing);
    expect(find.text(_l10n.reviewQueueEmpty), findsOneWidget);
  });

  testWidgets('offline: the decision stays to try again', (tester) async {
    final id = await other(newSong('First'));
    await open(tester, AppRoutes.reviewItem(id));
    contributions.failure = const NetworkFailure('offline');
    await tap(tester, find.text(_l10n.reviewApprove));
    expect(find.text(_l10n.reviewOffline), findsOneWidget);
    expect(find.byType(ReviewItemScreen), findsOneWidget);
  });

  testWidgets('library fingerprints: publish one, drop another', (
    tester,
  ) async {
    PendingFingerprint waiting(String id, String recording, int installs) =>
        PendingFingerprint(
          id: id,
          recordingId: recording,
          songId: 'selam',
          songTitle: 'Selam',
          recordingArtist: 'Abebe Choir',
          recordingDuration: const Duration(minutes: 3),
          frameCount: 7752,
          hashCount: 18000,
          installs: installs,
          sentAt: DateTime.utc(2026, 11, 13),
        );
    contributions.pending.addAll([
      waiting('f1', 'rec-1', 1),
      waiting('f2', 'rec-2', 2),
    ]);
    await open(tester, AppRoutes.reviewQueue);

    expect(find.text(_l10n.reviewQueueFingerprints), findsOneWidget);
    expect(find.text('Selam · Abebe Choir'), findsNWidgets(2));
    expect(find.textContaining('2 phones'), findsOneWidget);
    expect(find.textContaining('file 3:00, recording 3:00'), findsNWidgets(2));

    await tap(tester, find.byTooltip(_l10n.reviewFingerprintPublish).first);
    expect(contributions.fingerprintReviews, [('f1', true)]);
    await tap(tester, find.byTooltip(_l10n.reviewFingerprintDrop));
    expect(contributions.fingerprintReviews.last, ('f2', false));
    expect(find.text(_l10n.reviewQueueFingerprints), findsNothing);
  });
}
