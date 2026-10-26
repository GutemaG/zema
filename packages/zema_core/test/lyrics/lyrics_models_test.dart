import 'dart:convert';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const _song = Song(
  id: 'selam-leki',
  title: 'ሰላም ለኪ',
  transliteration: 'Selam Leki',
  artist: 'ዘማሪት',
  album: 'ምስጋና',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [
        LyricLine('ሰላም ለኪ ማርያም', transliteration: 'Selam leki Mariam'),
        LyricLine('እመ ብርሃን'),
      ],
    ),
    LyricSection(
      id: 'c',
      kind: SectionKind.chorus,
      lines: [LyricLine('ሃሌ ሉያ')],
    ),
  ],
  playOrder: ['v1', 'c', 'c'],
);

const _recording = Recording(
  id: 'selam-leki-1',
  songId: 'selam-leki',
  source: RecordingSource.bundled,
  artist: 'Choir',
  duration: Duration(minutes: 3, seconds: 5),
  offset: Duration(milliseconds: -250),
);

const _timing = SyncTiming(
  recordingId: 'selam-leki-1',
  starts: [
    Duration(seconds: 2),
    Duration(seconds: 6),
    Duration(seconds: 10),
    Duration(milliseconds: 14500),
  ],
);

/// Through a JSON string, as stored data would be.
Object? _roundTrip(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

void main() {
  group('JSON', () {
    test('a song survives a round trip', () {
      expect(Song.fromJson(_roundTrip(_song.toJson())), _song);
    });

    test('a recording and a timing survive a round trip', () {
      expect(Recording.fromJson(_roundTrip(_recording.toJson())), _recording);
      expect(SyncTiming.fromJson(_roundTrip(_timing.toJson())), _timing);
    });

    test('optional fields are left out and default when read', () {
      const song = Song(
        id: 's',
        title: 'T',
        sections: [LyricSection(id: 'a', kind: SectionKind.other, lines: [])],
      );
      final json = song.toJson();
      expect(json.keys, ['id', 'title', 'sections']);
      expect(Song.fromJson(_roundTrip(json)), song);

      const recording = Recording(
        id: 'r',
        songId: 's',
        source: RecordingSource.localFile,
      );
      expect(recording.toJson().keys, ['id', 'songId', 'source']);
      final read = Recording.fromJson(_roundTrip(recording.toJson()));
      expect(read.offset, Duration.zero);
      expect(read.duration, isNull);
    });

    test('times are whole milliseconds', () {
      expect(_timing.toJson()['startsMs'], [2000, 6000, 10000, 14500]);
      expect(_recording.toJson()['offsetMs'], -250);
      expect(_recording.toJson()['durationMs'], 185000);
    });

    test('Ethiopic text is kept exactly', () {
      final json = jsonEncode(_song.toJson());
      expect(json, contains('ሰላም ለኪ ማርያም'));
      expect(
        Song.fromJson(jsonDecode(json)).sections.first.lines.first.text,
        'ሰላም ለኪ ማርያም',
      );
    });

    group('malformed data gives LyricsFormatFailure', () {
      final cases = <String, Object? Function()>{
        'not an object': () => Song.fromJson('song'),
        'missing title': () =>
            Song.fromJson({'id': 's', 'sections': <Object?>[]}),
        'title not a string': () =>
            Song.fromJson({'id': 's', 'title': 3, 'sections': <Object?>[]}),
        'sections not a list': () => Song.fromJson({
          'id': 's',
          'title': 'T',
          'sections': <String, Object?>{},
        }),
        'unknown section kind': () => Song.fromJson({
          'id': 's',
          'title': 'T',
          'sections': [
            {'id': 'a', 'kind': 'refrain', 'lines': <Object?>[]},
          ],
        }),
        'transliteration not a string': () =>
            LyricLine.fromJson({'text': 'a', 'transliteration': 3}),
        'line without text': () => LyricLine.fromJson({'transliteration': 'x'}),
        'play order with a number': () => Song.fromJson({
          'id': 's',
          'title': 'T',
          'sections': <Object?>[],
          'playOrder': [1],
        }),
        'unknown source': () =>
            Recording.fromJson({'id': 'r', 'songId': 's', 'source': 'cd'}),
        'offset not a whole number': () => Recording.fromJson({
          'id': 'r',
          'songId': 's',
          'source': 'bundled',
          'offsetMs': 0.5,
        }),
        'start not milliseconds': () => SyncTiming.fromJson({
          'recordingId': 'r',
          'startsMs': ['00:01'],
        }),
      };
      for (final MapEntry(key: name, value: read) in cases.entries) {
        test(name, () {
          expect(read, throwsA(isA<LyricsFormatFailure>()));
        });
      }
    });
  });

  group('equality', () {
    test('compares by value', () {
      final copy = Song.fromJson(_song.toJson());
      expect(copy, _song);
      expect(copy.hashCode, _song.hashCode);
      expect(
        Recording.fromJson(_recording.toJson()).hashCode,
        _recording.hashCode,
      );
      expect(SyncTiming.fromJson(_timing.toJson()).hashCode, _timing.hashCode);
      expect(
        Song.fromJson({
          ..._song.toJson(),
          'playOrder': ['v1', 'c'],
        }),
        isNot(_song),
      );
      expect(
        const LyricLine('a'),
        isNot(const LyricLine('a', transliteration: 'a')),
      );
      expect(
        const SyncTiming(recordingId: 'r', starts: [Duration(seconds: 1)]),
        isNot(
          const SyncTiming(recordingId: 'r', starts: [Duration(seconds: 2)]),
        ),
      );
    });
  });
}
