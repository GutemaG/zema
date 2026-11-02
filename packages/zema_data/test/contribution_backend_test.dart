@Tags(['backend'])
library;

import 'dart:convert';
import 'dart:math';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'support/local_backend.dart';

/// Contributions against the local backend: submitting, the moderator's
/// queue and review, publishing, and how refusals reach the app.
void main() {
  final key = localAnonKey();
  final serviceKey = localServiceKey();
  final skip = key == null || serviceKey == null ? backendNotRunning : null;
  final random = Random();
  final open = <SupabaseAuthRepository>[];
  late SupabaseClient service;

  // What the tests leave on the server, removed afterwards.
  final contributionIds = <String>[];
  final songIds = <String>[];

  setUpAll(() {
    if (skip == null) service = SupabaseClient(localUrl, serviceKey!);
  });

  tearDownAll(() async {
    if (skip != null) return;
    if (contributionIds.isNotEmpty) {
      await service
          .from('contributions')
          .delete()
          .inFilter('id', contributionIds);
    }
    if (songIds.isNotEmpty) {
      await service.from('songs').delete().inFilter('id', songIds);
    }
    await service.dispose();
  });

  tearDown(() async {
    for (final auth in open) {
      await auth.run('delete_account', (c, _) => c.rpc<void>('delete_account'));
      await auth.close();
    }
    open.clear();
  });

  /// A new signed-in user, a moderator when [moderator].
  Future<SupabaseContributionRepository> user({
    String name = 'Test User',
    bool moderator = false,
  }) async {
    final email = 'zema-data-${random.nextInt(1 << 32)}@example.com';
    final client = SupabaseClient(
      localUrl,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final String session;
    try {
      final response = await client.auth.signUp(
        email: email,
        password: 'Test-pass-12345',
        data: {'full_name': name},
      );
      session = jsonEncode(response.session!.toJson());
    } finally {
      await client.dispose();
    }
    if (moderator) {
      await service.rpc<Object?>(
        'set_moderator',
        params: {'email': email, 'enabled': true},
      );
    }
    final auth = SupabaseAuthRepository(
      url: localUrl,
      key: key,
      store: MemorySessionStore(session),
    );
    open.add(auth);
    await auth.restore();
    return SupabaseContributionRepository(auth);
  }

  /// A new song only these tests use.
  Song song() {
    final id = 'zema-data-test-${random.nextInt(1 << 32)}';
    return Song(
      id: id,
      title: 'Test Song',
      sections: const [
        LyricSection(
          id: 'v1',
          kind: SectionKind.verse,
          lines: [LyricLine('one'), LyricLine('two')],
        ),
      ],
      playOrder: const ['v1', 'v1'],
    );
  }

  Future<String> submit(
    SupabaseContributionRepository repository,
    Contribution contribution,
  ) async {
    final id = await repository.submit(contribution);
    contributionIds.add(id);
    return id;
  }

  Matcher refused(ContributionError error) =>
      isA<ContributionFailure>().having((f) => f.error, 'error', error);

  group('contributions on the local backend', skip: skip, () {
    test('submit, review, resubmit, reject: each seen by its author', () async {
      final author = await user(name: 'Almaz');
      final moderator = await user(moderator: true);
      final first = Contribution.newSong(song());

      final id = await submit(author, first);
      final [sent] = await author.mine();
      expect(sent.id, id);
      expect(sent.status, ContributionStatus.pending);
      expect(
        sent.contribution,
        first,
        reason: 'the payload comes back exactly',
      );
      expect(sent.revision, 1);

      final queued = (await moderator.queue()).singleWhere((q) => q.id == id);
      expect(queued.authorName, 'Almaz');
      expect(queued.contribution, first);
      expect(queued.currentSong, isNull, reason: 'a new song');
      expect(
        (await moderator.queue(kind: ContributionKind.syncTiming))
            .where((q) => q.id == id),
        isEmpty,
      );

      expect(
        await moderator.review(
          id,
          ReviewDecision.requestChanges,
          note: 'Add the second verse',
        ),
        isNull,
      );
      final [back] = await author.mine();
      expect(back.status, ContributionStatus.changesRequested);
      expect(back.reviewNote, 'Add the second verse');
      expect(back.reviewedAt, isNotNull);

      final fixed = Contribution.newSong(
        Song(
          id: first.song!.id,
          title: 'Test Song (fixed)',
          sections: first.song!.sections,
          playOrder: first.song!.playOrder,
        ),
      );
      expect(await author.resubmit(id, fixed), 2);
      final [again] = await author.mine();
      expect(again.status, ContributionStatus.pending);
      expect(again.revision, 2);
      expect(again.contribution, fixed);

      await moderator.review(id, ReviewDecision.reject, note: 'Duplicate');
      final [rejected] = await author.mine();
      expect(rejected.status, ContributionStatus.rejected);
      expect(rejected.reviewNote, 'Duplicate');
    });

    test('an approved new song is published with its recording', () async {
      final author = await user();
      final moderator = await user(moderator: true);
      final s = song();
      final recording = Recording(
        id: newRecordingId(),
        songId: s.id,
        source: RecordingSource.localFile,
        duration: const Duration(minutes: 3),
        fileName: 'Test Song.mp3',
      );
      final id = await submit(
        author,
        Contribution.newSong(
          s,
          recording: recording,
          timing: SyncTiming(
            recordingId: recording.id,
            starts: const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 3),
              Duration(seconds: 4),
            ],
          ),
        ),
      );

      final published = await moderator.review(id, ReviewDecision.approve);
      expect(published, s.id);
      songIds.add(published!);

      final catalog = SupabaseCatalogRepository(url: localUrl, key: key!);
      try {
        final document = await catalog.song(published);
        expect(document!.song.title, 'Test Song');
        expect(document.recordings.single.fileName, 'Test Song.mp3');
        expect(document.timings.single.starts, hasLength(4));
      } finally {
        await catalog.close();
      }
      final [approved] = await author.mine();
      expect(approved.status, ContributionStatus.approved);
      expect(approved.songId, published);
    });

    test('refusals reach the app with their code', () async {
      final author = await user();
      final moderator = await user(moderator: true);

      // A broken rule (the backend checks again).
      final s = song();
      await expectLater(
        author.submit(
          Contribution.newSong(
            s,
            recording: Recording(
              id: newRecordingId(),
              songId: s.id,
              source: RecordingSource.localFile,
              fileName: 'a.mp3',
            ),
            timing: const SyncTiming(
              recordingId: 'other',
              starts: [Duration(seconds: 1)],
            ),
          ),
        ),
        throwsA(refused(ContributionError.unknownRecording)),
      );

      // Not a moderator (HTTP 403).
      await expectLater(
        author.queue(),
        throwsA(refused(ContributionError.notModerator)),
      );

      // A second review (HTTP 409).
      final id = await submit(author, Contribution.newSong(song()));
      await moderator.review(id, ReviewDecision.reject, note: 'No');
      await expectLater(
        moderator.review(id, ReviewDecision.approve),
        throwsA(refused(ContributionError.alreadyReviewed)),
      );

      // A note is required.
      final other = await submit(author, Contribution.newSong(song()));
      await expectLater(
        moderator.review(other, ReviewDecision.requestChanges),
        throwsA(refused(ContributionError.noteRequired)),
      );

      // The open limit (HTTP 429): one is pending, 19 more make 20.
      for (var i = 0; i < 19; i++) {
        await submit(author, Contribution.newSong(song()));
      }
      await expectLater(
        author.submit(Contribution.newSong(song())),
        throwsA(refused(ContributionError.tooManyOpen)),
      );
    });

    test('signed out: an auth failure, nothing sent', () async {
      final auth = SupabaseAuthRepository(
        url: localUrl,
        key: key!,
        store: MemorySessionStore(),
      );
      try {
        await auth.restore();
        await expectLater(
          SupabaseContributionRepository(auth)
              .submit(Contribution.newSong(song())),
          throwsA(isA<AuthFailure>()),
        );
      } finally {
        await auth.close();
      }
    });
  });
}
