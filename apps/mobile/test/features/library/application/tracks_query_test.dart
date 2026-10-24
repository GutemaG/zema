import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/tracks_query.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

Track _track(
  int id,
  String title, {
  String? artist,
  String? album,
  int seconds = 60,
  int day = 1,
}) {
  final audio = scannedAudio(
    id,
    '/m/$id.mp3',
    title: title,
    artist: artist,
    album: album,
    durationMs: seconds * 1000,
  );
  return Track.fromScan(
    id,
    audio,
  ).copyWith(dateAdded: DateTime.utc(2026, 1, day));
}

List<String> _titles(List<Track> tracks) => [for (final t in tracks) t.title];

void main() {
  final tracks = [
    _track(1, 'kidus', artist: 'Zerfe', album: 'Vol 1', seconds: 90, day: 3),
    _track(2, 'Amlak', artist: 'zerfe', album: 'Vol 2', seconds: 30, day: 1),
    _track(3, 'ሰላም ለኪ', artist: 'ዘማሪት', seconds: 120, day: 2),
    _track(4, 'Tselot', album: 'Telegram', seconds: 45, day: 4),
  ];

  group('filterTracks', () {
    test('matches title, artist or album, ignoring case and spaces', () {
      expect(_titles(filterTracks(tracks, 'KIDUS')), ['kidus']);
      expect(_titles(filterTracks(tracks, ' zerfe ')), ['kidus', 'Amlak']);
      expect(_titles(filterTracks(tracks, 'telegram')), ['Tselot']);
      expect(_titles(filterTracks(tracks, 'ሰላም')), ['ሰላም ለኪ']);
    });

    test('keeps everything for an empty query and nothing for no match', () {
      expect(filterTracks(tracks, '  '), tracks);
      expect(filterTracks(tracks, 'zzz'), isEmpty);
    });
  });

  group('sortTracks', () {
    test('sorts by title ignoring case, both ways', () {
      const asc = TrackSort(TrackSortField.title);
      const desc = TrackSort(TrackSortField.title, descending: true);

      expect(_titles(sortTracks(tracks, asc)), [
        'Amlak',
        'kidus',
        'Tselot',
        'ሰላም ለኪ',
      ]);
      expect(_titles(sortTracks(tracks, desc)), [
        'ሰላም ለኪ',
        'Tselot',
        'kidus',
        'Amlak',
      ]);
    });

    test('puts tracks without an artist or album last in both directions', () {
      for (final descending in [false, true]) {
        final byArtist = sortTracks(
          tracks,
          TrackSort(TrackSortField.artist, descending: descending),
        );
        final byAlbum = sortTracks(
          tracks,
          TrackSort(TrackSortField.album, descending: descending),
        );
        expect(byArtist.last.title, 'Tselot', reason: '$descending');
        expect(byAlbum.last.title, 'ሰላም ለኪ', reason: '$descending');
      }
    });

    test('breaks ties by title so the order is stable', () {
      final byArtist = sortTracks(
        tracks,
        const TrackSort(TrackSortField.artist),
      );

      // "zerfe" and "Zerfe" tie; titles decide.
      expect(_titles(byArtist).take(2), ['Amlak', 'kidus']);
    });

    test('sorts by date added and by duration', () {
      expect(
        _titles(sortTracks(tracks, const TrackSort(TrackSortField.dateAdded))),
        ['Amlak', 'ሰላም ለኪ', 'kidus', 'Tselot'],
      );
      expect(
        _titles(
          sortTracks(
            tracks,
            const TrackSort(TrackSortField.duration, descending: true),
          ),
        ),
        ['ሰላም ለኪ', 'kidus', 'Tselot', 'Amlak'],
      );
    });

    test('does not change the input list', () {
      final copy = [...tracks];
      sortTracks(tracks, const TrackSort(TrackSortField.duration));
      expect(tracks, copy);
    });
  });

  group('initialOf', () {
    test('uses uppercase Latin letters', () {
      expect(initialOf('amlak'), 'A');
      expect(initialOf('  Zema'), 'Z');
    });

    test('uses the Ethiopic consonant family', () {
      expect(initialOf('ሰላም'), 'ሰ');
      expect(initialOf('ሱባኤ'), 'ሰ');
      expect(initialOf('ቁርባን'), 'ቀ');
      expect(initialOf('እግዚአብሔር'), 'አ');
      expect(initialOf('ኢየሱስ'), 'አ');
    });

    test('groups digits, symbols, other scripts and blanks under #', () {
      expect(initialOf('7 Kidus'), '#');
      expect(initialOf('(Live)'), '#');
      expect(initialOf('Ägypten'), '#');
      expect(initialOf(''), '#');
      expect(initialOf(null), '#');
    });
  });

  group('sectionStarts', () {
    test('gives the first index of each initial', () {
      const sort = TrackSort(TrackSortField.title);
      final sorted = sortTracks(tracks, sort);

      expect(sectionStarts(sorted, sort), {'A': 0, 'K': 1, 'T': 2, 'ሰ': 3});
    });

    test('groups missing artists under #', () {
      const sort = TrackSort(TrackSortField.artist);
      final sorted = sortTracks(tracks, sort);

      expect(sectionStarts(sorted, sort).keys, ['Z', 'ዘ', '#']);
    });
  });

  test('only text sorts are alphabetical', () {
    expect(const TrackSort(TrackSortField.album).isAlphabetical, isTrue);
    expect(const TrackSort(TrackSortField.duration).isAlphabetical, isFalse);
  });
}
