import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

Duration _s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// Lines start at 5, 10, 15 and 20 s.
final _engine = SyncEngine([_s(5), _s(10), _s(15), _s(20)]);

SyncPosition _at(num seconds, {num offset = 0}) =>
    _engine.at(_s(seconds), offset: _s(offset));

void main() {
  group('SyncEngine.at', () {
    test('before the first line: nothing current, the first is next', () {
      expect(_at(0), const SyncPosition(current: null, next: 0));
      expect(_at(4.99), const SyncPosition(current: null, next: 0));
    });

    test('each line is current from its start until the next start', () {
      expect(_at(5), const SyncPosition(current: 0, next: 1));
      expect(_at(9.99), const SyncPosition(current: 0, next: 1));
      expect(_at(10), const SyncPosition(current: 1, next: 2));
      expect(_at(17), const SyncPosition(current: 2, next: 3));
    });

    test('after the last line starts it stays current, with no next', () {
      expect(_at(20), const SyncPosition(current: 3, next: null));
      expect(_at(600), const SyncPosition(current: 3, next: null));
    });

    test('is right 0.3 s either side of every boundary', () {
      final starts = [5, 10, 15, 20];
      for (final (i, start) in starts.indexed) {
        expect(
          _at(start - 0.3).current,
          i == 0 ? null : i - 1,
          reason: '$start-',
        );
        expect(_at(start + 0.3).current, i, reason: '$start+');
      }
    });

    test('a positive offset shows lines later, a negative one earlier', () {
      // Line 1 starts at 10 s.
      expect(_at(10.4, offset: 0.5).current, 0);
      expect(_at(10.5, offset: 0.5).current, 1);
      expect(_at(9.6, offset: -0.5).current, 1);
      expect(_at(9.4, offset: -0.5).current, 0);
      expect(_at(10.9, offset: 1).current, 0);
      expect(_at(11, offset: 1).current, 1);
      expect(_at(9, offset: -1).current, 1);
      expect(_at(8.9, offset: -1).current, 0);
    });

    test('an offset can move the first line before 0 or after the end', () {
      expect(_at(0, offset: -5).current, 0);
      expect(_at(24, offset: 5).current, 2);
    });

    test('seeking either way finds the right line straight away', () {
      final positions = [18, 3, 12, 6, 21, 0, 15];
      final expected = [2, null, 1, 0, 3, null, 2];
      for (final (i, p) in positions.indexed) {
        expect(_at(p).current, expected[i], reason: 'at $p s');
      }
    });

    test('lines starting together: the later one is current', () {
      final engine = SyncEngine([_s(1), _s(4), _s(4), _s(8)]);
      expect(engine.at(_s(4)), const SyncPosition(current: 2, next: 3));
      expect(engine.at(_s(3.9)), const SyncPosition(current: 0, next: 1));
    });

    test('no lines: nothing current or next', () {
      final engine = SyncEngine(const []);
      expect(engine.lineCount, 0);
      expect(engine.at(_s(5)), const SyncPosition(current: null, next: null));
    });

    test('starts going backwards are rejected', () {
      expect(
        () => SyncEngine([_s(1), _s(5), _s(3)]),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });
  });

  group('SyncEngine.startOf', () {
    test('is where tapping a line seeks, with the same offset', () {
      expect(_engine.startOf(1), _s(10));
      expect(_engine.startOf(1, offset: _s(0.5)), _s(10.5));
      expect(_engine.startOf(2, offset: _s(-1)), _s(14));
      // Seeking there makes that line current.
      for (final offset in [-1, -0.5, 0, 0.5, 1]) {
        final o = _s(offset);
        expect(_engine.at(_engine.startOf(2, offset: o), offset: o).current, 2);
      }
    });

    test('never seeks before the start', () {
      expect(_engine.startOf(0, offset: _s(-8)), Duration.zero);
    });
  });

  group('SyncedLyrics.of', () {
    const song = Song(
      id: 's',
      title: 'T',
      sections: [
        LyricSection(
          id: 'v',
          kind: SectionKind.verse,
          lines: [LyricLine('a'), LyricLine('b')],
        ),
        LyricSection(
          id: 'c',
          kind: SectionKind.chorus,
          lines: [LyricLine('c')],
        ),
      ],
      playOrder: ['v', 'c', 'c'],
    );

    test('pairs every sung line with its start', () {
      final lyrics = SyncedLyrics.of(
        song,
        SyncTiming(recordingId: 'r', starts: [_s(1), _s(3), _s(5), _s(9)]),
      );

      expect([for (final l in lyrics.lines) l.line.text], ['a', 'b', 'c', 'c']);
      expect(lyrics.engine.lineCount, 4);
      expect(lyrics.engine.at(_s(9.5)).current, 3);
      expect(lyrics.lines[3].repeat, 1);
    });

    test('rejects timing with too few or too many starts', () {
      for (final count in [3, 5]) {
        expect(
          () => SyncedLyrics.of(
            song,
            SyncTiming(
              recordingId: 'r',
              starts: [for (var i = 0; i < count; i++) _s(i)],
            ),
          ),
          throwsA(isA<LyricsFormatFailure>()),
          reason: '$count starts',
        );
      }
    });

    test('rejects timing that goes backwards', () {
      expect(
        () => SyncedLyrics.of(
          song,
          SyncTiming(recordingId: 'r', starts: [_s(1), _s(5), _s(3), _s(9)]),
        ),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });
  });

  test('accuracy: each line starts within 1 ms of its timing, with offset', () {
    // The ±0.3 s target leaves room for the player's position updates
    // (at most every 200 ms); the engine itself adds no delay.
    final starts = [
      for (var i = 0; i < 40; i++) Duration(milliseconds: 1500 + i * 2350),
    ];
    final engine = SyncEngine(starts);
    for (final offset in const [
      Duration.zero,
      Duration(milliseconds: 500),
      Duration(milliseconds: -1500),
    ]) {
      for (var i = 0; i < starts.length; i++) {
        final start = starts[i] + offset;
        expect(
          engine
              .at(start - const Duration(milliseconds: 1), offset: offset)
              .current,
          i == 0 ? null : i - 1,
        );
        expect(engine.at(start, offset: offset).current, i);
        expect(
          engine.startOf(i, offset: offset),
          start < Duration.zero ? Duration.zero : start,
        );
      }
    }
  });
}
