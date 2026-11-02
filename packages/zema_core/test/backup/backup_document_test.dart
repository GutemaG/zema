import 'dart:convert';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const tizita = TrackIdentity(
  title: 'Tizita',
  artist: 'Mahmoud Ahmed',
  album: 'Ere Mela Mela',
  durationMs: 241000,
  fileName: 'Tizita.mp3',
);
const ambassel = TrackIdentity(
  title: 'Ambassel',
  durationMs: 198500,
  fileName: '02 Ambassel.flac',
);

final created = DateTime.utc(2026, 10, 30, 10);

BackupDocument fullDocument() => BackupDocument(
  createdAt: created,
  favorites: [
    BackupFavorite(track: tizita, addedAt: DateTime.utc(2026, 1, 2, 3, 4, 5)),
    BackupFavorite(track: ambassel, addedAt: DateTime.utc(2026, 2)),
  ],
  playlists: [
    BackupPlaylist(
      name: 'Morning',
      description: 'Slow ones',
      createdAt: DateTime.utc(2025, 12, 31),
      tracks: const [ambassel, tizita],
    ),
    const BackupPlaylist(name: 'Empty', tracks: []),
  ],
  lyricsChoices: const [
    BackupLyricsChoice(track: tizita, songId: 'song-1'),
    BackupLyricsChoice(track: ambassel),
  ],
  hiddenFolders: const ['Recordings', 'WhatsApp/Media/WhatsApp Audio'],
  hiddenTracks: const [ambassel],
  settings: const {'themeMode': 'dark', 'minTrackSeconds': 30, 'gapless': true},
  songInfo: const [
    BackupSongInfo(track: ambassel, title: 'Ambasel', trackNumber: 2),
  ],
  syncOffsets: const {'rec-1': Duration(milliseconds: -500)},
);

void main() {
  group('TrackIdentity', () {
    test('of a track: tags, duration and only the file name', () {
      final track = Track(
        id: 7,
        mediaStoreId: 70,
        uri: 'content://media/70',
        path: '/storage/emulated/0/Music/Mahmoud/Tizita.mp3',
        title: 'Tizita',
        artist: 'Mahmoud Ahmed',
        album: 'Ere Mela Mela',
        duration: const Duration(minutes: 4, seconds: 1),
        sizeBytes: 1,
        dateAdded: DateTime.utc(2026),
      );
      expect(TrackIdentity.ofTrack(track), tizita);
    });

    test('no artist or album stays null, and is left out of the JSON', () {
      expect(ambassel.toJson(), {
        'title': 'Ambassel',
        'ms': 198500,
        'file': '02 Ambassel.flac',
      });
      final back = TrackIdentity.fromJson(ambassel.toJson());
      expect(back.artist, isNull);
      expect(back.album, isNull);
      expect(back, ambassel);
    });

    test('fileNameOf keeps the last part only', () {
      expect(fileNameOf('/a/b/c.mp3'), 'c.mp3');
      expect(fileNameOf('c.mp3'), 'c.mp3');
    });
  });

  group('BackupDocument', () {
    test('format 1', () {
      expect(backupFormat, 1);
      expect(fullDocument().toJson()['format'], 1);
    });

    test('round-trips exactly through JSON text', () {
      final document = fullDocument();
      final back = BackupDocument.decode(document.encode());
      expect(back, document);
      expect(back.encode(), document.encode());
      expect(back.favorites.first.addedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(back.playlists.first.tracks, [ambassel, tizita]);
      expect(back.lyricsChoices.last.songId, isNull);
    });

    test('an empty document round-trips', () {
      final empty = BackupDocument(createdAt: created);
      expect(BackupDocument.decode(empty.encode()), empty);
    });

    test('each track is written once; sections refer to it by index', () {
      final json = fullDocument().toJson();
      expect(json['tracks'], [tizita.toJson(), ambassel.toJson()]);
      expect(json['favorites'], [
        {'track': 0, 'addedAt': '2026-01-02T03:04:05.000Z'},
        {'track': 1, 'addedAt': '2026-02-01T00:00:00.000Z'},
      ]);
      expect((json['playlists']! as List).first, {
        'name': 'Morning',
        'description': 'Slow ones',
        'createdAt': '2025-12-31T00:00:00.000Z',
        'tracks': [1, 0],
      });
      expect(json['hiddenTracks'], [1]);
    });

    test('dates are written in UTC', () {
      final local = DateTime(2026, 3, 4, 5, 6);
      final json = BackupDocument(createdAt: local).toJson();
      expect(json['createdAt'], local.toUtc().toIso8601String());
      expect(BackupDocument.fromJson(json).createdAt, local.toUtc());
    });

    test('unknown sections from a newer app are kept and written back', () {
      final json = fullDocument().toJson()
        ..['equalizer'] = [
          {'track': 0, 'bass': 2},
        ]
        ..['floatingLyrics'] = {'opacity': 0.8};
      final document = BackupDocument.fromJson(json);
      expect(document.extras.keys, {'equalizer', 'floatingLyrics'});
      final again = document.toJson();
      expect(again['equalizer'], json['equalizer']);
      expect(again['floatingLyrics'], {'opacity': 0.8});
    });

    test('unknown fields inside entries are ignored', () {
      final json = jsonDecode(fullDocument().encode()) as Map<String, Object?>;
      (json['tracks']! as List).cast<Map<String, Object?>>().first['bpm'] = 90;
      (json['favorites']! as List)
              .cast<Map<String, Object?>>()
              .first['rating'] =
          5;
      (json['playlists']! as List).cast<Map<String, Object?>>().first['color'] =
          'red';
      expect(BackupDocument.fromJson(json), fullDocument());
    });

    test('missing sections read as empty', () {
      final document = BackupDocument.fromJson({
        'format': 1,
        'createdAt': '2026-10-30T10:00:00.000Z',
      });
      expect(document.favorites, isEmpty);
      expect(document.playlists, isEmpty);
      expect(document.settings, isEmpty);
      expect(document.songInfo, isEmpty);
      expect(document.syncOffsets, isEmpty);
      expect(document.extras, isEmpty);
    });

    test('song info carries its track, not an index, so an older app that '
        'keeps it unread writes it back still right', () {
      final json = fullDocument().toJson();
      final info = (json['songInfo']! as List).single as Map<String, Object?>;
      expect(info['track'], ambassel.toJson());
      expect(info['title'], 'Ambasel');
      expect(info.containsKey('artist'), isFalse);
      expect(json['syncOffsets'], {'rec-1': -500});
      expect(
        BackupDocument.decode(jsonEncode(json)).songInfo,
        fullDocument().songInfo,
      );
    });

    test('a newer format says so, so the app can ask for an update', () {
      final json = fullDocument().toJson()..['format'] = 2;
      expect(
        () => BackupDocument.fromJson(json),
        throwsA(
          isA<BackupFormatFailure>().having(
            (f) => f.newerFormat,
            'newerFormat',
            isTrue,
          ),
        ),
      );
    });

    test('malformed documents fail as BackupFormatFailure, not newer', () {
      final bad = <String>[
        'not json',
        '[1, 2]',
        '{"createdAt": "2026-10-30T10:00:00Z"}',
        '{"format": 0, "createdAt": "2026-10-30T10:00:00Z"}',
        '{"format": 1}',
        '{"format": 1, "createdAt": "yesterday"}',
        '{"format": 1, "createdAt": "2026-10-30T10:00:00Z", "favorites": [{"track": 3, "addedAt": "2026-10-30T10:00:00Z"}]}',
        '{"format": 1, "createdAt": "2026-10-30T10:00:00Z", "tracks": [{"title": 5, "ms": 1, "file": "a"}]}',
        '{"format": 1, "createdAt": "2026-10-30T10:00:00Z", "playlists": {"a": 1}}',
      ];
      for (final source in bad) {
        expect(
          () => BackupDocument.decode(source),
          throwsA(
            isA<BackupFormatFailure>().having(
              (f) => f.newerFormat,
              'newerFormat',
              isFalse,
            ),
          ),
          reason: source,
        );
      }
    });

    test('1,000 favorites + 50 playlists × 100 songs, all different, is '
        'under 1 MB', () {
      // Typical tag lengths, and every track distinct: the worst case.
      TrackIdentity track(int i) => TrackIdentity(
        title: 'Song title number $i x',
        artist: 'Artist name $i',
        album: 'Album title $i xxxx',
        durationMs: 180000 + i,
        fileName: '${i.toString().padLeft(2, '0')} Song title number $i.mp3',
      );
      final document = BackupDocument(
        createdAt: created,
        favorites: [
          for (var i = 0; i < 1000; i++)
            BackupFavorite(track: track(i), addedAt: created),
        ],
        playlists: [
          for (var p = 0; p < 50; p++)
            BackupPlaylist(
              name: 'Playlist $p',
              tracks: [for (var i = 0; i < 100; i++) track(1000 + p * 100 + i)],
            ),
        ],
      );
      final bytes = utf8.encode(document.encode()).length;
      expect(bytes, lessThan(1024 * 1024), reason: '$bytes bytes');
      expect(BackupDocument.decode(document.encode()), document);
    });
  });
}
