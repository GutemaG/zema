import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/artist_grouping.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

var _nextId = 1;
Track _track(String title, {String? artist, String? album, int? year}) {
  final id = _nextId++;
  return Track.fromScan(
    id,
    scannedAudio(
      id,
      '/m/$id.mp3',
      title: title,
      artist: artist,
      album: album,
      year: year,
    ),
  );
}

void main() {
  group('groupArtists', () {
    final artists = groupArtists([
      _track('Zion', artist: 'Zerfe', album: 'Old', year: 2001),
      _track('Amen', artist: 'Zerfe', album: 'New', year: 2020),
      _track('Single', artist: 'Zerfe'),
      _track('ሰላም', artist: 'ዘማሪት'),
      _track('Duet', artist: 'A & B', album: 'Duets'),
      _track('Untagged'),
    ]);

    test('by name, as written, with "Unknown artist" last', () {
      expect(
        [for (final a in artists) a.name],
        ['A & B', 'Zerfe', 'ዘማሪት', null],
      );
    });

    test('songs by title and albums newest first, unknown album last', () {
      final zerfe = artists[1];

      expect(
        [for (final t in zerfe.tracks) t.title],
        ['Amen', 'Single', 'Zion'],
      );
      expect([for (final a in zerfe.albums) a.title], ['New', 'Old', null]);
    });

    test("the avatar is their newest named album's cover", () {
      expect(artists[1].cover.title, 'Amen');
    });

    test('without a named album the avatar is their first song', () {
      expect(artists[2].cover.title, 'ሰላም');
      expect(artists[3].cover.title, 'Untagged');
    });

    test('an empty library has no artists', () {
      expect(groupArtists(const []), isEmpty);
    });
  });
}
