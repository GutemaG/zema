@Tags(['backend'])
library;

import 'dart:convert';
import 'dart:math';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'support/local_backend.dart';

/// Reports and hidden songs against the local backend (intent 008).
void main() {
  final key = localAnonKey();
  final serviceKey = localServiceKey();
  final skip = key == null || serviceKey == null ? backendNotRunning : null;
  final random = Random();
  final open = <SupabaseAuthRepository>[];
  late SupabaseClient service;
  late String songId;

  setUpAll(() async {
    if (skip != null) return;
    service = SupabaseClient(localUrl, serviceKey!);
    songId = 'zema-data-mod-${random.nextInt(1 << 32)}';
    await service.rpc<Object?>(
      'seed_song',
      params: {
        'doc': {
          'song': {
            'id': songId,
            'title': 'Moderation Test $songId',
            'artist': 'Test Artist',
            'sections': [
              {
                'id': 'v',
                'kind': 'verse',
                'lines': [
                  {'text': 'one'},
                  {'text': 'two'},
                ],
              },
            ],
            'playOrder': ['v'],
          },
        },
      },
    );
  });

  tearDownAll(() async {
    if (skip != null) return;
    await service.from('reports').delete().eq('song_id', songId);
    await service.from('songs').delete().eq('id', songId);
    await service.dispose();
  });

  tearDown(() async {
    for (final auth in open) {
      await auth.run('delete_account', (c, _) => c.rpc<void>('delete_account'));
      await auth.close();
    }
    open.clear();
  });

  Future<SupabaseModerationRepository> user({bool moderator = false}) async {
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
    return SupabaseModerationRepository(auth);
  }

  Matcher refused(String code) =>
      isA<ContributionFailure>().having((f) => f.code, 'code', code);

  group('moderation on the local backend', skip: skip, () {
    test('only moderators', () async {
      final listener = await user();
      await expectLater(
        listener.reports(ReportStatus.open),
        throwsA(refused('not_moderator')),
      );
      await expectLater(
        listener.setHidden(songId, hidden: true),
        throwsA(refused('not_moderator')),
      );
    });

    test('reports: read and resolved', () async {
      final inserted = await service
          .from('reports')
          .insert({
            'song_id': songId,
            'reason': 'wrong_timing',
            'note': 'late',
            'install_hash': 'test',
          })
          .select('id')
          .single();
      final id = inserted['id'] as String;
      final moderator = await user(moderator: true);

      final report = (await moderator.reports(ReportStatus.open))
          .singleWhere((r) => r.id == id);
      expect(report.songTitle, 'Moderation Test $songId');
      expect(report.reason, ReportReason.wrongTiming);
      expect(report.note, 'late');

      await moderator.resolveReport(id, ReportStatus.resolved);
      expect(
        (await moderator.reports(ReportStatus.open)).map((r) => r.id),
        isNot(contains(id)),
      );
      expect(
        (await moderator.reports(null)).singleWhere((r) => r.id == id).status,
        ReportStatus.resolved,
      );
      await expectLater(
        moderator.resolveReport(id, ReportStatus.open),
        throwsA(refused('bad_status')),
      );
    });

    test('songs: hidden from listeners, then shown again', () async {
      final moderator = await user(moderator: true);
      final catalog = SupabaseCatalogRepository(url: localUrl, key: key!);
      addTearDown(catalog.close);

      var found = await moderator.songs(query: songId);
      expect(found.single.hidden, isFalse);
      expect(found.single.lineCount, 2);
      expect(found.single.artist, 'Test Artist');

      await moderator.setHidden(songId, hidden: true);
      found = await moderator.songs(query: songId);
      expect(found.single.hidden, isTrue);
      expect((await catalog.index()).map((e) => e.id), isNot(contains(songId)));
      expect(await catalog.song(songId), isNull);
      expect((await moderator.song(songId))?.song.sections.single.lines, [
        const LyricLine('one'),
        const LyricLine('two'),
      ]);

      await moderator.setHidden(songId, hidden: false);
      expect((await catalog.index()).map((e) => e.id), contains(songId));

      await expectLater(
        moderator.setHidden('zema-no-such-song', hidden: true),
        throwsA(refused('unknown_song')),
      );
    });
  });
}
