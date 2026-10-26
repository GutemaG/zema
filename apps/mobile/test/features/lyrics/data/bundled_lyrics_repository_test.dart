import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/lyrics/data/bundled_lyrics_repository.dart';
import 'package:zema_core/zema_core.dart';

/// An asset bundle holding [files] (path under assets/lyrics → text).
class _FakeAssets extends CachingAssetBundle {
  _FakeAssets(this.files);

  final Map<String, String> files;
  int loads = 0;

  /// Counts every read, before the bundle's own cache.
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    loads++;
    return super.loadString(key, cache: false);
  }

  @override
  Future<ByteData> load(String key) async {
    final name = key.replaceFirst('${BundledLyricsRepository.folder}/', '');
    final text = files[name];
    if (text == null) throw StateError('No asset $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}

String _index(List<Map<String, Object?>> songs) => jsonEncode({'songs': songs});

const _lrc = '[ti:Amen]\n[ar:Choir]\n[00:01]a\n[tr:ah]\n[00:02]b\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bundled samples', () {
    final repository = BundledLyricsRepository(rootBundle);

    test('three songs load, each fitting its timing', () async {
      final songs = await repository.songs();
      expect(
        [for (final s in songs) s.id],
        ['birhan-honlin', 'selam-lezih-bet', 'galatoomi'],
      );
      for (final song in songs) {
        final recordings = await repository.recordings(song.id);
        expect(recordings, hasLength(1), reason: song.id);
        final timing = await repository.timing(recordings.single.id);
        expect(timing, isNotNull, reason: song.id);
        final lyrics = SyncedLyrics.of(song, timing!);
        expect(song.playOrder, ['v1', 'c', 'v2', 'c', 'c'], reason: song.id);
        expect(lyrics.lines.length, greaterThanOrEqualTo(10), reason: song.id);
        expect(recordings.single.duration, isNotNull, reason: song.id);
        expect(
          timing.starts.last,
          lessThan(recordings.single.duration!),
          reason: '${song.id}: the last line starts before the end',
        );
      }
    });

    test('Amharic songs carry transliterations', () async {
      final song = (await repository.song('birhan-honlin'))!;
      expect(song.title, 'ብርሃን ሆንልን');
      expect(song.transliteration, 'Birhan Honlin');
      expect(song.sections.first.lines.first.transliteration, isNotNull);
    });

    test(
      'search finds them by title, transliteration and Latin spelling',
      () async {
        Future<List<String>> ids(String q) async => [
          for (final s in await repository.search(q)) s.id,
        ];
        expect(await ids('birhan'), ['birhan-honlin']);
        expect(await ids('ሰላም'), ['selam-lezih-bet']);
        expect(await ids('selam'), ['selam-lezih-bet']);
        expect(await ids('galatoomi'), ['galatoomi']);
        expect(await ids('nothing like it'), isEmpty);
      },
    );

    test('unknown IDs give nothing', () async {
      expect(await repository.song('nope'), isNull);
      expect(await repository.recordings('nope'), isEmpty);
      expect(await repository.timing('nope'), isNull);
    });
  });

  group('BundledLyricsRepository', () {
    test('reads the files once', () async {
      final assets = _FakeAssets({
        'index.json': _index([
          {'id': 'amen', 'file': 'amen.lrc', 'durationMs': 5000},
        ]),
        'amen.lrc': _lrc,
      });
      final repository = BundledLyricsRepository(assets);

      await repository.songs();
      await repository.song('amen');
      await repository.search('amen');

      expect(assets.loads, 2);
      final recording = (await repository.recordings('amen')).single;
      expect(recording.duration, const Duration(seconds: 5));
      expect(recording.artist, 'Choir');
    });

    test(
      'skips missing, malformed, misfitting and duplicate entries',
      () async {
        final repository = BundledLyricsRepository(
          _FakeAssets({
            'index.json': _index([
              {'id': 'good', 'file': 'good.lrc'},
              {'id': 'missing', 'file': 'missing.lrc'},
              {'id': 'empty', 'file': 'empty.lrc'},
              {'file': 'no-id.lrc'},
              {'id': 'good', 'file': 'other.lrc'},
              {'id': 'last', 'file': 'last.lrc'},
            ]),
            'good.lrc': _lrc,
            'empty.lrc': '[ti:Nothing timed]',
            'other.lrc': '[ti:Other]\n[00:01]x\n',
            'last.lrc': '[ti:Last]\n[00:01]y\n',
          }),
        );

        expect(
          [for (final s in await repository.songs()) s.id],
          ['good', 'last'],
        );
        expect((await repository.song('good'))!.title, 'Amen');
      },
    );

    test('an unreadable index is a LyricsFormatFailure', () async {
      for (final files in [
        <String, String>{},
        {'index.json': '{not json'},
        {'index.json': '{"songs": 3}'},
      ]) {
        expect(
          BundledLyricsRepository(_FakeAssets(files)).songs(),
          throwsA(isA<LyricsFormatFailure>()),
          reason: '$files',
        );
      }
    });
  });
}
