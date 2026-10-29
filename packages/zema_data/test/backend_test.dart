@Tags(['backend'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'support/local_backend.dart';

/// Against the local backend and its seed (`backend/seed/`).

void main() {
  final key = localAnonKey();
  final skip = key == null ? backendNotRunning : null;
  final repositories = <SupabaseCatalogRepository>[];

  SupabaseCatalogRepository connect({String url = localUrl, String? withKey}) {
    final repository = SupabaseCatalogRepository(
      url: url,
      key: withKey ?? key!,
    );
    repositories.add(repository);
    return repository;
  }

  tearDown(() async {
    for (final r in repositories) {
      await r.close();
    }
    repositories.clear();
  });

  group('the local backend', skip: skip, () {
    final seed = _seedSongs(backendDir);

    test('index lists every seeded song', () async {
      final index = await connect().index();
      expect([
        for (final e in index) e.id,
      ], [for (final s in seed) s.song.id]..sort());
      final first = index.firstWhere((e) => e.id == seed.first.song.id);
      expect(first.title, seed.first.song.title);
      expect(first.synced, isTrue);
      expect(first.version, greaterThan(0));
    });

    test('song returns what zema_core imports from the seed files', () async {
      final repository = connect();
      for (final expected in seed) {
        final document = await repository.song(expected.song.id);
        expect(document!.song, expected.song);
        expect(document.recordings, [expected.recording]);
        expect(document.timings, [expected.timing]);
      }
    });

    test('song is null for an unknown ID', () async {
      expect(await connect().song('no-such-song'), isNull);
    });

    test('search finds a song by title and by a lyric line', () async {
      final repository = connect();
      final song = seed.first.song;
      final byTitle = await repository.search(song.title);
      expect(byTitle.first.songId, song.id);
      expect(byTitle.first.line, isNull);

      final line = song.sections.last.lines.last.text;
      final byLine = await repository.search(line);
      expect(byLine.where((h) => h.songId == song.id).first.line, isNotNull);
    });

    test('five reports a day are stored, the sixth is refused', () async {
      final repository = connect();
      final installId = 'zema-data-test-${Random().nextInt(1 << 32)}';
      addTearDown(() => _deleteReports(installId));
      for (var i = 0; i < 5; i++) {
        await repository.report(
          songId: seed.first.song.id,
          reason: ReportReason.wrongTiming,
          installId: installId,
          recordingId: seed.first.recording.id,
          note: 'zema_data test $i',
        );
      }
      await expectLater(
        repository.report(
          songId: seed.first.song.id,
          reason: ReportReason.other,
          installId: installId,
        ),
        throwsA(isA<RateLimitFailure>()),
      );
      expect(_reportCount(installId), 5);
    });

    test('a report for an unknown song is a BackendFailure', () async {
      await expectLater(
        connect().report(
          songId: 'no-such-song',
          reason: ReportReason.other,
          installId: 'zema-data-test-unknown',
        ),
        throwsA(isA<BackendFailure>()),
      );
    });

    test('a wrong key is a BackendFailure', () async {
      await expectLater(
        connect(withKey: 'not-a-key').index(),
        throwsA(isA<BackendFailure>()),
      );
    });
  });

  test('an unreachable backend is a NetworkFailure', () async {
    await expectLater(
      connect(url: 'http://127.0.0.1:1', withKey: 'any').index(),
      throwsA(isA<NetworkFailure>()),
    );
  });
}

/// The local backend's anon key, or null when it isn't running.
/// The seeded songs, as zema_core imports them from `backend/seed/`.
List<CatalogSong> _seedSongs(Directory backendDir) {
  final seedDir = Directory('${backendDir.path}/seed');
  if (!seedDir.existsSync()) return const [];
  final index = jsonDecode(
    File('${seedDir.path}/index.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return [
    for (final entry in (index['songs']! as List).cast<Map<String, Object?>>())
      if ((entry['status'] ?? 'approved') == 'approved')
        importIndexedLrc(
          entry,
          File('${seedDir.path}/${entry['file']}').readAsStringSync(),
        ),
  ];
}

/// Runs [sql] in the local database container.
String _psql(String sql) {
  final result = Process.runSync('docker', [
    'exec',
    'supabase_db_zema',
    'psql',
    '-U',
    'postgres',
    '-tAc',
    sql,
  ]);
  if (result.exitCode != 0) throw StateError('psql: ${result.stderr}');
  return (result.stdout as String).trim();
}

String _hashSql(String installId) =>
    "encode(extensions.digest('$installId', 'sha256'), 'hex')";

int _reportCount(String installId) => int.parse(
  _psql(
    'select count(*) from public.reports '
    'where install_hash = ${_hashSql(installId)}',
  ),
);

void _deleteReports(String installId) => _psql(
  'delete from public.reports where install_hash = ${_hashSql(installId)}',
);
