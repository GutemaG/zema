import 'package:flutter_test/flutter_test.dart';
import 'package:zema_core/zema_core.dart';

import 'fake_auth.dart';
import 'fake_contributions.dart';

const song = Song(
  id: 'selam',
  title: 'Selam',
  sections: [
    LyricSection(id: 'v1', kind: SectionKind.verse, lines: [LyricLine('a')]),
  ],
  playOrder: ['v1'],
);

const moderatorId = 'moderator-1';

void main() {
  late FakeContributionRepository repo;

  setUp(() => repo = FakeContributionRepository());

  Matcher refused(ContributionError error) => throwsA(
    isA<ContributionFailure>().having((f) => f.error, 'error', error),
  );

  /// Acts as the moderator for [body], then as the test user again.
  Future<T> asModerator<T>(Future<T> Function() body) async {
    repo
      ..userId = moderatorId
      ..moderator = true;
    try {
      return await body();
    } finally {
      repo
        ..userId = testUser.id
        ..moderator = false;
    }
  }

  test('submit, review, resubmit, as on the backend', () async {
    final id = await repo.submit(const Contribution.newSong(song));
    expect((await repo.mine()).single.status, ContributionStatus.pending);

    final queued = await asModerator(repo.queue);
    expect(queued.single.authorName, testUser.name);
    await asModerator(
      () => repo.review(id, ReviewDecision.requestChanges, note: ' Fix '),
    );
    final back = (await repo.mine()).single;
    expect(back.status, ContributionStatus.changesRequested);
    expect(back.reviewNote, 'Fix');

    expect(await repo.resubmit(id, const Contribution.newSong(song)), 2);
    expect(
      await asModerator(() => repo.review(id, ReviewDecision.approve)),
      'selam',
    );
    expect((await repo.mine()).single.status, ContributionStatus.approved);
    expect(repo.sent, hasLength(2));
  });

  test('the shared rules and the limits', () async {
    expect(
      repo.submit(
        const Contribution.newSong(
          Song(id: 'x', title: ' ', sections: [], playOrder: []),
        ),
      ),
      refused(ContributionError.titleRequired),
    );
    expect(
      repo.submit(
        const Contribution.syncTiming(
          songId: 'nope',
          timing: SyncTiming(recordingId: 'r', starts: []),
        ),
      ),
      refused(ContributionError.unknownSong),
    );
    for (var i = 0; i < 20; i++) {
      await repo.submit(const Contribution.newSong(song));
    }
    expect(
      repo.submit(const Contribution.newSong(song)),
      refused(ContributionError.tooManyOpen),
    );
  });

  test('syncs are checked against the catalog song', () async {
    repo.songs['selam'] = const SongDocument(
      song: song,
      recordings: [
        Recording(
          id: 'r1',
          songId: 'selam',
          source: RecordingSource.localFile,
          fileName: 'a.mp3',
        ),
      ],
    );
    await repo.submit(
      const Contribution.syncTiming(
        songId: 'selam',
        timing: SyncTiming(recordingId: 'r1', starts: [Duration(seconds: 1)]),
      ),
    );
    expect(
      repo.submit(
        const Contribution.syncTiming(
          songId: 'selam',
          timing: SyncTiming(recordingId: 'r9', starts: [Duration(seconds: 1)]),
        ),
      ),
      refused(ContributionError.unknownRecording),
    );
    expect(
      repo.submit(
        const Contribution.syncTiming(
          songId: 'selam',
          timing: SyncTiming(
            recordingId: 'r1',
            starts: [Duration(seconds: 1), Duration(seconds: 2)],
          ),
        ),
      ),
      refused(ContributionError.timingCount),
    );
  });

  test(
    'reviews: moderators only, never their own, once, with a note',
    () async {
      final id = await repo.submit(const Contribution.newSong(song));
      expect(repo.queue(), refused(ContributionError.notModerator));
      expect(
        repo.review(id, ReviewDecision.approve),
        refused(ContributionError.notModerator),
      );
      await asModerator(() async {
        expect(
          repo.review(id, ReviewDecision.reject),
          refused(ContributionError.noteRequired),
        );
        await repo.review(id, ReviewDecision.reject, note: 'Duplicate');
        expect(
          repo.review(id, ReviewDecision.approve),
          refused(ContributionError.alreadyReviewed),
        );
        final own = await repo.submit(const Contribution.newSong(song));
        expect(
          repo.review(own, ReviewDecision.approve),
          refused(ContributionError.ownContribution),
        );
        expect(await repo.queue(), isEmpty, reason: 'not their own');
      });
    },
  );

  test('resubmit only the author\'s "changes requested"', () async {
    final id = await repo.submit(const Contribution.newSong(song));
    expect(
      repo.resubmit(id, const Contribution.newSong(song)),
      refused(ContributionError.notEditable),
    );
  });

  test('signed out, or a set failure', () async {
    repo.failure = const NetworkFailure('offline');
    expect(repo.mine(), throwsA(isA<NetworkFailure>()));
    repo.userId = null;
    expect(repo.mine(), throwsA(isA<AuthFailure>()));
  });
}
