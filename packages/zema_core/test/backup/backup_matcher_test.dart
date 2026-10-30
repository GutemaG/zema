import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

var _ids = 0;

Track track(
  String path, {
  String? title,
  String? artist,
  int ms = 200000,
  bool missing = false,
  int? id,
}) {
  final name = fileNameOf(path);
  return Track(
    id: id ?? ++_ids,
    mediaStoreId: 0,
    uri: 'content://$path',
    path: path,
    title: title ?? name.substring(0, name.lastIndexOf('.')),
    artist: artist,
    duration: Duration(milliseconds: ms),
    sizeBytes: 1,
    dateAdded: DateTime.utc(2026),
    missing: missing,
  );
}

TrackIdentity identity(
  String file, {
  String title = 'Song',
  String? artist,
  int ms = 200000,
}) =>
    TrackIdentity(title: title, artist: artist, durationMs: ms, fileName: file);

void main() {
  group('rule 1: file name and length', () {
    test('matches in any folder and letter case, within ±2 s', () {
      final a = track('/new/phone/Music/Tizita.mp3', ms: 241000);
      final matcher = BackupTrackMatcher([a]);
      expect(matcher.match(identity('Tizita.mp3', ms: 241000)), a);
      expect(matcher.match(identity('tizita.MP3', ms: 243000)), a);
      expect(matcher.match(identity('Tizita.mp3', ms: 239000)), a);
    });

    test('not when the length is off by more than 2 s', () {
      final matcher = BackupTrackMatcher([track('/m/Tizita.mp3', ms: 241000)]);
      expect(matcher.match(identity('Tizita.mp3', ms: 243001)), isNull);
      expect(matcher.match(identity('Tizita.mp3', ms: 238999)), isNull);
    });

    test('works without an artist on either side', () {
      final a = track('/m/untagged_mezmur.mp3', ms: 35000);
      final matcher = BackupTrackMatcher([a]);
      expect(
        matcher.match(identity('untagged_mezmur.mp3', title: 'x', ms: 35000)),
        a,
      );
    });

    test('the closest length wins among same-named files, then the lowest '
        'ID', () {
      final far = track('/a/01.mp3', ms: 201500, id: 10);
      final near = track('/b/01.mp3', ms: 200400, id: 20);
      final tie = track('/c/01.mp3', ms: 199600, id: 5);
      final matcher = BackupTrackMatcher([far, near, tie]);
      expect(matcher.match(identity('01.mp3', ms: 200000)), tie);
    });
  });

  group('rule 2: title, artist and length', () {
    test('ignores case, spacing and punctuation', () {
      final a = track(
        '/m/renamed.mp3',
        title: 'Tizita (Live)',
        artist: 'Mahmoud  Ahmed',
        ms: 241000,
      );
      final matcher = BackupTrackMatcher([a]);
      expect(
        matcher.match(
          identity(
            'Tizita.mp3',
            title: 'tizita - live',
            artist: 'MAHMOUD AHMED',
            ms: 242500,
          ),
        ),
        a,
      );
    });

    test('ignores Ethiopic spelling variants and ፡ ።', () {
      final a = track(
        '/m/x.mp3',
        title: 'ሰላም፡ለኪ።',
        artist: 'ዘማሪት ዘርፌ',
        ms: 48000,
      );
      final matcher = BackupTrackMatcher([a]);
      expect(
        matcher.match(
          identity('y.mp3', title: 'ሠላም ለኪ', artist: 'ዘማሪት ዘርፌ', ms: 48000),
        ),
        a,
      );
    });

    test('never on the title alone', () {
      final noArtist = track('/m/a.mp3', title: 'Amlak', ms: 75000);
      final otherArtist = track(
        '/m/b.mp3',
        title: 'Amlak',
        artist: 'Someone Else',
        ms: 75000,
      );
      final matcher = BackupTrackMatcher([noArtist, otherArtist]);
      expect(
        matcher.match(identity('c.mp3', title: 'Amlak', ms: 75000)),
        isNull,
        reason: 'the backed-up song has no artist',
      );
      expect(
        matcher.match(
          identity('c.mp3', title: 'Amlak', artist: 'Zerfe Kebede', ms: 75000),
        ),
        isNull,
        reason: 'a different artist',
      );
    });

    test('not when the length is off by more than 2 s', () {
      final matcher = BackupTrackMatcher([
        track('/m/a.mp3', title: 'Amlak', artist: 'Zerfe', ms: 75000),
      ]);
      expect(
        matcher.match(
          identity('b.mp3', title: 'Amlak', artist: 'Zerfe', ms: 78000),
        ),
        isNull,
      );
    });

    test('a title of only noise or punctuation is never matched on', () {
      final matcher = BackupTrackMatcher([
        track('/m/a.mp3', title: '!!!', artist: 'Zerfe', ms: 1000),
      ]);
      expect(
        matcher.match(
          identity('b.mp3', title: '???', artist: 'Zerfe', ms: 1000),
        ),
        isNull,
      );
    });
  });

  test('the file name rule comes first', () {
    final byFile = track('/m/Amlak.mp3', title: 'Other', ms: 75000);
    final byTags = track(
      '/m/renamed.mp3',
      title: 'Amlak',
      artist: 'Zerfe',
      ms: 75000,
    );
    final matcher = BackupTrackMatcher([byTags, byFile]);
    expect(
      matcher.match(
        identity('Amlak.mp3', title: 'Amlak', artist: 'Zerfe', ms: 75000),
      ),
      byFile,
    );
  });

  test('missing tracks are never matched', () {
    final matcher = BackupTrackMatcher([
      track('/m/a.mp3', ms: 1000, missing: true),
    ]);
    expect(matcher.match(identity('a.mp3', ms: 1000)), isNull);
  });

  test('the same files on a new phone: ≥ 95% matched, none wrongly', () {
    // A realistic library on phone A, and how it looks on phone B after the
    // user copied their music over: other folders, some files renamed,
    // some re-encoded (lengths differ by up to 1.5 s), some re-tagged, a
    // few left behind.
    final songs = <(String file, String title, String? artist, int ms)>[
      for (final (i, (title, artist)) in const [
        ('Tizita', 'Mahmoud Ahmed'),
        ('Ere Mela Mela', 'Mahmoud Ahmed'),
        ('Ambassel', 'Aster Aweke'),
        ('Kabu', 'Aster Aweke'),
        ('Yene Konjo', 'Teddy Afro'),
        ('Lambadina', 'Teddy Afro'),
        ('Amlak', 'Zerfe Kebede'),
        ('Kidus Kidus', 'Zerfe Kebede'),
        ('ሰላም ለኪ', 'ዘማሪት ዘርፌ ከበደ'),
        ('ቅዱስ ቅዱስ ቅዱስ', 'ሊቀ መዘምራን ይልማ ኃይሉ'),
        ('እግዚአብሔር እረኛዬ ነው', 'ዘማሪ ደረጀ ከበደ'),
        ('ምስጋና', 'ዘማሪት ትዕግስት'),
        ('Tselot', 'Mahlet Hailu'),
        ('Tsome Digua', 'Tewodros Yosef'),
        ('Galatoomi', 'Zema Samples'),
        ('Waaqayyo Gaariidha', 'Galaanaa Gaaromsaa'),
        ('Yesus Kristos', 'Addisu Worku'),
        ('Hallelujah', 'Meskerem Getu'),
        ('Abet Abet', 'Gigi'),
        ('Gud Fella', 'Tilahun Gessesse'),
      ].indexed)
        for (var take = 0; take < 5; take++)
          (
            '${(i * 5 + take).toString().padLeft(3, '0')} $title${take == 0 ? '' : ' $take'}.mp3',
            take == 0 ? title : '$title $take',
            artist,
            150000 + i * 7919 + take * 1013,
          ),
      // Untagged recordings: file name only.
      for (var i = 0; i < 10; i++)
        ('voice_mezmur_$i.m4a', 'voice_mezmur_$i', null, 60000 + i * 997),
    ];

    final backedUp = [
      for (final (file, title, artist, ms) in songs)
        identity(file, title: title, artist: artist, ms: ms),
    ];

    final phoneB = <Track>[];
    final expected = <TrackIdentity, Track>{};
    final notCopied = <TrackIdentity>{};
    for (final (n, (file, title, artist, ms)) in songs.indexed) {
      final id = backedUp[n];
      if (n % 37 == 5) {
        notCopied.add(id); // left behind
        continue;
      }
      var newFile = file;
      var newTitle = title;
      var newMs = ms;
      if (n % 9 == 1 && artist != null) {
        newFile = '$artist - $title.mp3'; // renamed, tags kept
      }
      if (n % 7 == 2) newMs = ms + (n.isEven ? 1500 : -1500); // re-encoded
      if (n % 11 == 3) newTitle = title.toUpperCase(); // re-tagged
      if (n % 13 == 4 && artist != null) {
        newFile = 'track${n}_copy.mp3';
        newTitle = '$title!';
      }
      final t = track(
        '/storage/emulated/0/Download/Music backup/$newFile',
        title: newTitle,
        artist: artist,
        ms: newMs,
      );
      phoneB.add(t);
      expected[id] = t;
    }
    // Other music on phone B that was never backed up.
    for (var i = 0; i < 40; i++) {
      phoneB.add(
        track(
          '/storage/emulated/0/Music/other_$i.mp3',
          artist: 'X',
          ms: 99000 + i,
        ),
      );
    }

    final matcher = BackupTrackMatcher(phoneB);
    var right = 0;
    for (final id in backedUp) {
      final found = matcher.match(id);
      if (notCopied.contains(id)) {
        expect(found, isNull, reason: '$id was not copied');
      } else if (found != null) {
        expect(found, expected[id], reason: 'wrong match for $id');
        right++;
      }
    }
    final rate = right / expected.length;
    expect(rate, greaterThanOrEqualTo(0.95), reason: 'matched $rate');
  });

  test('2,000 entries against 5,000 tracks in under 2 s', () {
    final tracks = [
      for (var i = 0; i < 5000; i++)
        track(
          '/storage/emulated/0/Music/Artist ${i % 300}/Song number $i.mp3',
          title: 'Song number $i',
          artist: 'Artist ${i % 300}',
          ms: 120000 + i * 13,
        ),
    ];
    final ids = [
      for (var i = 0; i < 2000; i++)
        identity(
          // Half by file name, half renamed so only the tags can match.
          i.isEven ? 'Song number ${i * 2}.mp3' : 'renamed_$i.mp3',
          title: 'Song number ${i * 2}',
          artist: 'Artist ${(i * 2) % 300}',
          ms: 120000 + i * 2 * 13,
        ),
    ];

    final watch = Stopwatch()..start();
    final matcher = BackupTrackMatcher(tracks);
    final matched = ids.map(matcher.match).whereType<Track>().length;
    watch.stop();

    expect(matched, 2000);
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
