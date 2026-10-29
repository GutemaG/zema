import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const _lrc = '''
[ti:ሰላም]
[ar:Zema]
[offset:+250]
[00:01.00][00:05.00]ሃሌ ሉያ
[00:02.00][00:06.00]ሃሌ
[00:03.00]ሰላም ለኪ
''';

void main() {
  test('an index entry and its LRC become song, recording and timing', () {
    final song = importIndexedLrc({
      'id': 'selam',
      'file': 'selam.lrc',
      'transliteration': 'Selam',
      'durationMs': 30000,
    }, _lrc);
    expect(song.song.id, 'selam');
    expect(song.song.title, 'ሰላም');
    expect(song.song.transliteration, 'Selam');
    expect(song.recording.id, 'selam');
    expect(song.recording.duration, const Duration(seconds: 30));
    expect(song.recording.offset, const Duration(milliseconds: -250));
    expect(song.timing.starts, hasLength(5));
    expect(song.skipped, isEmpty);
  });

  test('its document is the backend get_song shape', () {
    final song = importIndexedLrc({'id': 'selam', 'file': 'x'}, _lrc);
    final doc = song.toDocument();
    expect(doc.keys, ['song', 'recordings', 'timings']);
    expect(doc['song'], song.song.toJson());
    expect(doc['recordings'], [song.recording.toJson()]);
    expect(doc['timings'], [song.timing.toJson()]);
  });

  test('an entry without id or file fails', () {
    for (final entry in [
      <String, Object?>{'file': 'x.lrc'},
      <String, Object?>{'id': 'x'},
      <String, Object?>{'id': 1, 'file': 'x.lrc'},
    ]) {
      expect(
        () => importIndexedLrc(entry, _lrc),
        throwsA(isA<LyricsFormatFailure>()),
        reason: '$entry',
      );
    }
  });

  test('LRC without timed lines fails', () {
    expect(
      () => importIndexedLrc({'id': 'x', 'file': 'x'}, '[ti:Nothing]'),
      throwsA(isA<LyricsFormatFailure>()),
    );
  });
}
