import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

ScannedAudio _audio(
  int mediaStoreId,
  String path, {
  String? title,
  bool untagged = false,
  int sizeBytes = 1000,
  int durationMs = 60000,
  String? artist,
}) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  return ScannedAudio(
    mediaStoreId: mediaStoreId,
    uri: 'content://media/external/audio/media/$mediaStoreId',
    path: path,
    displayName: name,
    title: untagged ? null : title ?? name.replaceAll('.mp3', ''),
    artist: artist,
    duration: Duration(milliseconds: durationMs),
    sizeBytes: sizeBytes,
    dateAdded: DateTime.utc(2026, 10, 1),
  );
}

Track _stored(int id, ScannedAudio audio, {bool missing = false}) =>
    Track.fromScan(id, audio).copyWith(missing: missing);

void main() {
  group('reconcileTracks', () {
    test('adds every file when nothing is stored', () {
      final scan = [_audio(1, '/m/a.mp3'), _audio(2, '/m/b.mp3')];

      final result = reconcileTracks(stored: const [], scan: scan);

      expect(result.added, scan);
      expect(result.updated, isEmpty);
      expect(result.newlyMissing, isEmpty);
    });

    test('changes nothing when an unchanged library is rescanned', () {
      final a = _audio(1, '/m/a.mp3');
      final b = _audio(2, '/m/b.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, a), _stored(11, b)],
        scan: [a, b],
      );

      expect(result.isEmpty, isTrue);
    });

    test('keeps the ID and updates metadata when the path matches', () {
      final before = _audio(1, '/m/a.mp3', artist: 'Old');
      final after = _audio(1, '/m/a.mp3', artist: 'New');

      final result = reconcileTracks(
        stored: [_stored(10, before)],
        scan: [after],
      );

      expect(result.updated.single.id, 10);
      expect(result.updated.single.artist, 'New');
      expect(result.added, isEmpty);
    });

    test('changes no ID when every media store ID changed', () {
      final stored = [
        _stored(10, _audio(1, '/m/a.mp3')),
        _stored(11, _audio(2, '/m/b.mp3')),
      ];
      final scan = [_audio(901, '/m/a.mp3'), _audio(902, '/m/b.mp3')];

      final result = reconcileTracks(stored: stored, scan: scan);

      expect(result.added, isEmpty);
      expect(
        {for (final t in result.updated) t.id: t.mediaStoreId},
        {10: 901, 11: 902},
      );
    });

    test('re-links a moved file by fingerprint and keeps its ID', () {
      final before = _audio(1, '/Download/song.mp3', title: 'Kidus');
      final after = _audio(7, '/Music/Mezmur/song.mp3', title: 'Kidus');

      final result = reconcileTracks(
        stored: [_stored(10, before)],
        scan: [after],
      );

      expect(result.moved, {10});
      expect(result.updated.single.id, 10);
      expect(result.updated.single.path, '/Music/Mezmur/song.mp3');
      expect(result.updated.single.folder, '/Music/Mezmur');
      expect(result.added, isEmpty);
      expect(result.newlyMissing, isEmpty);
    });

    test('re-links a moved file with an Ethiopic title', () {
      final before = _audio(1, '/Download/ቅዱስ.mp3', title: 'ቅዱስ  ቅዱስ ቅዱስ');
      final after = _audio(2, '/Music/መዝሙር/ቅዱስ.mp3', title: ' ቅዱስ ቅዱስ ቅዱስ');

      final result = reconcileTracks(
        stored: [_stored(10, before)],
        scan: [after],
      );

      expect(result.moved, {10});
    });

    test('treats a file as new when its size differs', () {
      final before = _audio(1, '/Download/song.mp3', sizeBytes: 1000);
      final after = _audio(2, '/Music/song.mp3', sizeBytes: 1001);

      final result = reconcileTracks(
        stored: [_stored(10, before)],
        scan: [after],
      );

      expect(result.moved, isEmpty);
      expect(result.added, [after]);
      expect(result.newlyMissing, [10]);
    });

    test('matches durations that differ by less than half a second', () {
      final before = _audio(1, '/a/song.mp3', durationMs: 60200);
      final after = _audio(2, '/b/song.mp3', durationMs: 59900);

      final result = reconcileTracks(
        stored: [_stored(10, before)],
        scan: [after],
      );

      expect(result.moved, {10});
    });

    test('treats a moved file as new when two stored tracks share its '
        'fingerprint', () {
      final copy1 = _audio(1, '/a/song.mp3');
      final copy2 = _audio(2, '/b/song.mp3');
      final moved = _audio(3, '/c/song.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, copy1), _stored(11, copy2)],
        scan: [moved],
      );

      expect(result.moved, isEmpty);
      expect(result.added, [moved]);
      expect(result.newlyMissing, unorderedEquals([10, 11]));
    });

    test('treats both files as new when two new files share the fingerprint '
        'of one stored track', () {
      final gone = _audio(1, '/a/song.mp3');
      final copyA = _audio(2, '/b/song.mp3');
      final copyB = _audio(3, '/c/song.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, gone)],
        scan: [copyA, copyB],
      );

      expect(result.moved, isEmpty);
      expect(result.added, unorderedEquals([copyA, copyB]));
    });

    test('marks tracks missing instead of deleting them', () {
      final a = _audio(1, '/m/a.mp3');
      final b = _audio(2, '/m/b.mp3', sizeBytes: 2000);

      final result = reconcileTracks(
        stored: [_stored(10, a), _stored(11, b)],
        scan: [a],
      );

      expect(result.newlyMissing, [11]);
      expect(result.updated, isEmpty);
    });

    test('does not report already-missing tracks again', () {
      final a = _audio(1, '/m/a.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, a, missing: true)],
        scan: const [],
      );

      expect(result.newlyMissing, isEmpty);
      expect(result.isEmpty, isTrue);
    });

    test('brings a missing track back with the same ID', () {
      final a = _audio(1, '/m/a.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, a, missing: true)],
        scan: [_audio(5, '/m/a.mp3')],
      );

      expect(result.returned, {10});
      expect(result.updated.single.id, 10);
      expect(result.updated.single.missing, isFalse);
    });

    test('brings back a missing track that returned at a new path', () {
      final a = _audio(1, '/old/a.mp3');

      final result = reconcileTracks(
        stored: [_stored(10, a, missing: true)],
        scan: [_audio(5, '/new/a.mp3')],
      );

      expect(result.returned, {10});
      expect(result.moved, {10});
    });

    test('keeps only the first entry when the scan lists a path twice', () {
      final first = _audio(1, '/m/a.mp3');
      final second = _audio(2, '/m/a.mp3');

      final result = reconcileTracks(stored: const [], scan: [first, second]);

      expect(result.added, [first]);
    });
  });

  group('TrackFingerprint', () {
    test('ignores case and extra spaces in the title', () {
      final a = TrackFingerprint.ofScan(_audio(1, '/a.mp3', title: 'Kidus '));
      final b = TrackFingerprint.ofScan(_audio(2, '/b.mp3', title: ' KIDUS'));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('uses the file name when the title tag is blank', () {
      final audio = _audio(1, '/m/untagged_song.mp3', title: '  ');

      expect(TrackFingerprint.ofScan(audio).title, 'untagged_song');
    });

    test('matches the stored track built from the same scan', () {
      final audio = _audio(1, '/m/a.mp3', title: 'ሰላም ለኪ');

      expect(
        TrackFingerprint.ofTrack(Track.fromScan(1, audio)),
        TrackFingerprint.ofScan(audio),
      );
    });
  });

  group('folderOf', () {
    test('returns the parent folder', () {
      expect(
        folderOf('/storage/emulated/0/Music/a.mp3'),
        '/storage/emulated/0/Music',
      );
      expect(folderOf('/a.mp3'), '/');
      expect(folderOf('a.mp3'), '');
    });
  });

  group('resolveTitle', () {
    test('prefers the tag, then the file name without extension', () {
      expect(resolveTitle(_audio(1, '/m/x.mp3', title: 'Amlak')), 'Amlak');
      expect(resolveTitle(_audio(1, '/m/x.y.mp3', title: '')), 'x.y');
      expect(resolveTitle(_audio(1, '/m/x.ogg', untagged: true)), 'x');
      expect(resolveTitle(_audio(1, '/m/.hidden', untagged: true)), '.hidden');
    });
  });
}
