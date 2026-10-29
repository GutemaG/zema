import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  const song = Song(
    id: 'selam',
    title: 'ሰላም',
    sections: [
      LyricSection(
        id: 'v1',
        kind: SectionKind.verse,
        lines: [LyricLine('ሰላም ለኪ')],
      ),
    ],
  );
  const recording = Recording(
    id: 'selam',
    songId: 'selam',
    source: RecordingSource.localFile,
    offset: Duration(milliseconds: -250),
  );
  const timing = SyncTiming(recordingId: 'selam', starts: [Duration.zero]);

  group('SongDocument', () {
    test('reads what toJson writes', () {
      const document = SongDocument(
        song: song,
        recordings: [recording],
        timings: [timing],
      );
      final read = SongDocument.fromJson(document.toJson());
      expect(read.song, song);
      expect(read.recordings, [recording]);
      expect(read.timings, [timing]);
    });

    test('reads the catalog shape a CatalogSong writes', () {
      final imported = importIndexedLrc({
        'id': 'selam',
        'file': 'selam.lrc',
      }, '[ti:ሰላም]\n[00:01.00]ሰላም ለኪ\n');
      final read = SongDocument.fromJson(imported.toDocument());
      expect(read.song, imported.song);
      expect(read.recordings, [imported.recording]);
      expect(read.timings, [imported.timing]);
    });

    test('treats missing recordings and timings as none', () {
      final read = SongDocument.fromJson({'song': song.toJson()});
      expect(read.recordings, isEmpty);
      expect(read.timings, isEmpty);
    });

    for (final (what, json) in [
      ('not an object', <Object?>[]),
      ('no song', <String, Object?>{}),
      ('recordings not a list', {'song': song.toJson(), 'recordings': 'x'}),
      (
        'a malformed timing',
        {
          'song': song.toJson(),
          'timings': [
            {'recordingId': 'selam', 'startsMs': 'x'},
          ],
        },
      ),
    ]) {
      test('rejects $what', () {
        expect(
          () => SongDocument.fromJson(json),
          throwsA(isA<LyricsFormatFailure>()),
        );
      });
    }
  });

  test('CatalogEntry compares by value', () {
    CatalogEntry entry({int version = 1}) => CatalogEntry(
      id: 'selam',
      title: 'ሰላም',
      synced: true,
      version: version,
      approvedAt: DateTime.utc(2026, 10, 29),
    );
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
    expect(entry(version: 2), isNot(entry()));
  });

  test('the new failures are ZemaFailures', () {
    for (final failure in const <ZemaFailure>[
      NetworkFailure('offline'),
      RateLimitFailure('too many'),
      BackendFailure('refused'),
    ]) {
      expect(failure, isA<ZemaFailure>());
    }
  });
}
