import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema_admin/src/contributions_page.dart';
import 'package:zema_admin/src/fingerprints_page.dart';
import 'package:zema_admin/src/session.dart';
import 'package:zema_admin/src/strings.dart';
import 'package:zema_core/zema_core.dart';

Song _song(String title, List<String> lines) => Song(
  id: 'selam',
  title: title,
  artist: 'Tewodros',
  sections: [
    LyricSection(
      id: 'v',
      kind: SectionKind.verse,
      lines: [for (final l in lines) LyricLine(l)],
    ),
  ],
  playOrder: const ['v'],
);

final _now = DateTime.now();

final _edit = QueuedContribution(
  id: 'c-edit',
  contribution: Contribution.editLyrics(
    songId: 'selam',
    baseVersion: 1,
    song: _song('Selam', ['first line', 'fixed second']),
  ),
  submittedAt: _now.subtract(const Duration(hours: 3)),
  authorName: 'Abebe',
  currentVersion: 1,
  currentSong: SongDocument(
    song: _song('Selam', ['first line', 'wrong second']),
  ),
);

const _recording = Recording(
  id: 'rec-1',
  songId: 'selam',
  source: RecordingSource.youtube,
  artist: 'Live',
  youtubeId: 'abcdefghijk',
);

final _timing = QueuedContribution(
  id: 'c-timing',
  contribution: const Contribution.syncTiming(
    songId: 'selam',
    timing: SyncTiming(
      recordingId: 'rec-1',
      starts: [Duration(milliseconds: 1500), Duration(seconds: 7)],
    ),
  ),
  submittedAt: _now.subtract(const Duration(hours: 1)),
  revision: 2,
  previousNote: 'Line 2 is late',
  currentSong: SongDocument(
    song: _song('Selam', ['first line', 'wrong second']),
    recordings: const [_recording],
  ),
);

class _Repository implements ContributionRepository {
  _Repository(this.items);

  List<QueuedContribution> items;
  final kinds = <ContributionKind?>[];
  final reviews = <(String, ReviewDecision, String?)>[];
  ZemaFailure? failure;
  List<PendingFingerprint> fingerprints = [];
  final fingerprintReviews = <(String, bool)>[];

  @override
  Future<List<QueuedContribution>> queue({ContributionKind? kind}) async {
    kinds.add(kind);
    return [
      for (final i in items)
        if (kind == null || i.kind == kind) i,
    ];
  }

  @override
  Future<String?> review(
    String id,
    ReviewDecision decision, {
    String? note,
  }) async {
    if (failure case final f?) throw f;
    reviews.add((id, decision, note));
    items = [
      for (final i in items)
        if (i.id != id) i,
    ];
    return 'selam';
  }

  @override
  Future<List<PendingFingerprint>> pendingFingerprints() async => fingerprints;

  @override
  Future<void> reviewFingerprint(String id, {required bool approve}) async {
    fingerprintReviews.add((id, approve));
    fingerprints = [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;

  setUp(() => repository = _Repository([_edit, _timing]));

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(1400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('contributions', () {
    testWidgets('the queue, filtered by kind', (tester) async {
      await pump(tester, const ContributionsPage());
      expect(find.text('Selam'), findsNWidgets(2));
      expect(find.textContaining('by Abebe'), findsOneWidget);
      expect(find.textContaining(Strings.resubmitted), findsOneWidget);
      expect(find.text(Strings.pickOne), findsOneWidget);

      await tester.tap(find.text(Strings.syncTiming));
      await tester.pumpAndSettle();
      expect(repository.kinds.last, ContributionKind.syncTiming);
      expect(find.text('Selam'), findsOneWidget);
    });

    testWidgets('a correction: what changed, side by side', (tester) async {
      await pump(tester, const ContributionsPage());
      await tester.tap(find.textContaining('by Abebe'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.changes.toUpperCase()), findsOneWidget);
      expect(find.text('wrong second'), findsNWidgets(2));
      expect(find.text('fixed second'), findsNWidgets(2));
      expect(find.text(Strings.current.toUpperCase()), findsOneWidget);
      expect(find.text(Strings.submitted.toUpperCase()), findsOneWidget);
    });

    testWidgets('a timing: each line with its time, and the last note', (
      tester,
    ) async {
      await pump(tester, const ContributionsPage());
      await tester.tap(find.textContaining(Strings.resubmitted).first);
      await tester.pumpAndSettle();
      expect(find.text('0:01.5'), findsOneWidget);
      expect(find.text('0:07.0'), findsOneWidget);
      expect(find.text('Line 2 is late'), findsOneWidget);
      expect(
        find.textContaining('youtube.com/watch?v=abcdefghijk'),
        findsOneWidget,
      );
    });

    testWidgets('approve publishes and leaves the queue', (tester) async {
      await pump(tester, const ContributionsPage());
      await tester.tap(find.textContaining('by Abebe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.approve));
      await tester.pumpAndSettle();
      expect(repository.reviews, [('c-edit', ReviewDecision.approve, null)]);
      expect(find.text(Strings.approved), findsOneWidget);
      expect(find.textContaining('by Abebe'), findsNothing);
      expect(find.text(Strings.pickOne), findsOneWidget);
    });

    testWidgets('reject needs a note', (tester) async {
      await pump(tester, const ContributionsPage());
      await tester.tap(find.textContaining('by Abebe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.reject));
      await tester.pumpAndSettle();
      expect(find.text(Strings.noteRequired), findsOneWidget);
      expect(repository.reviews, isEmpty);

      await tester.enterText(find.byType(TextField), '  Not this song ');
      await tester.tap(find.text(Strings.reject));
      await tester.pumpAndSettle();
      expect(repository.reviews, [
        ('c-edit', ReviewDecision.reject, 'Not this song'),
      ]);
    });

    testWidgets('already reviewed: said, and the queue reloads', (
      tester,
    ) async {
      await pump(tester, const ContributionsPage());
      await tester.tap(find.textContaining('by Abebe'));
      await tester.pumpAndSettle();
      repository.failure = const ContributionFailure(
        'review_contribution: already_reviewed',
        code: 'already_reviewed',
      );
      final asked = repository.kinds.length;
      await tester.tap(find.text(Strings.approve));
      await tester.pumpAndSettle();
      expect(find.text(Strings.alreadyReviewed), findsOneWidget);
      expect(repository.kinds.length, asked + 1);
    });

    testWidgets('narrow: opens on its own page and closes when decided', (
      tester,
    ) async {
      await pump(tester, const ContributionsPage(), size: const Size(500, 900));
      expect(find.text(Strings.pickOne), findsNothing);
      await tester.tap(find.textContaining('by Abebe'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.text(Strings.approve));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
      expect(repository.reviews, hasLength(1));
    });

    testWidgets('nothing to review', (tester) async {
      repository.items = [];
      await pump(tester, const ContributionsPage());
      expect(find.text(Strings.queueEmpty), findsOneWidget);
    });
  });

  group('fingerprints', () {
    testWidgets('empty while uploads are paused', (tester) async {
      await pump(tester, const FingerprintsPage());
      expect(find.text(Strings.fingerprintsEmpty), findsOneWidget);
    });

    testWidgets('approve one', (tester) async {
      repository.fingerprints = [
        PendingFingerprint(
          id: 'f1',
          recordingId: 'rec-1',
          songId: 'selam',
          songTitle: 'Selam',
          frameCount: 100,
          hashCount: 2400,
          installs: 1,
          sentAt: _now,
          recordingDuration: const Duration(minutes: 4, seconds: 5),
        ),
      ];
      await pump(tester, const FingerprintsPage());
      expect(
        find.textContaining('4:05 · 2400 hashes · 1 phones'),
        findsOneWidget,
      );
      await tester.tap(find.text(Strings.approve));
      await tester.pumpAndSettle();
      expect(repository.fingerprintReviews, [('f1', true)]);
      expect(find.text(Strings.fingerprintsEmpty), findsOneWidget);
    });
  });
}
