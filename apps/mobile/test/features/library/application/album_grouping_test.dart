import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/album_grouping.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

var _nextId = 1;
Track _track(
  String title, {
  String? album,
  String? artist,
  String? albumArtist,
  int? trackNumber,
  int? year,
  int seconds = 60,
}) {
  final id = _nextId++;
  return Track.fromScan(
    id,
    scannedAudio(
      id,
      '/m/$id.mp3',
      title: title,
      album: album,
      artist: artist,
      albumArtist: albumArtist,
      trackNumber: trackNumber,
      year: year,
      durationMs: seconds * 1000,
    ),
  );
}

Album _only(List<Track> tracks) => groupAlbums(tracks).single;

void main() {
  group('groupAlbums', () {
    test('orders by track number, unnumbered last, then title', () {
      final album = _only([
        _track('Zeta', album: 'A'),
        _track('Three', album: 'A', trackNumber: 3),
        _track('One', album: 'A', trackNumber: 1),
        _track('alpha', album: 'A'),
      ]);

      expect(
        [for (final t in album.tracks) t.title],
        ['One', 'Three', 'alpha', 'Zeta'],
      );
      expect(album.cover.title, 'One');
    });

    test('totals the duration and picks the most common year', () {
      final album = _only([
        _track('a', album: 'A', year: 2019, seconds: 100),
        _track('b', album: 'A', year: 2019, seconds: 200),
        _track('c', album: 'A', year: 2020, seconds: 300),
        _track('d', album: 'A', seconds: 400),
      ]);

      expect(album.duration, const Duration(seconds: 1000));
      expect(album.year, 2019);
    });

    test('a tie between years picks the latest', () {
      final album = _only([
        _track('a', album: 'A', year: 2018),
        _track('b', album: 'A', year: 2021),
      ]);

      expect(album.year, 2021);
    });

    test('no years means no year', () {
      expect(_only([_track('a', album: 'A')]).year, isNull);
    });

    test('the album artist wins over song artists', () {
      final album = _only([
        _track('a', album: 'A', artist: 'X', albumArtist: 'Choir'),
        _track('b', album: 'A', artist: 'Y', albumArtist: 'Choir'),
      ]);

      expect(album.artist, 'Choir');
      expect(album.variousArtists, isFalse);
    });

    test('one shared artist is the album artist', () {
      final album = _only([
        _track('a', album: 'A', artist: 'X'),
        _track('b', album: 'A', artist: 'X'),
      ]);

      expect(album.artist, 'X');
      expect(album.variousArtists, isFalse);
    });

    test('different artists and no album artist are various artists', () {
      final album = _only([
        _track('a', album: 'A', artist: 'X'),
        _track('b', album: 'A', artist: 'Y'),
      ]);

      expect(album.artist, isNull);
      expect(album.variousArtists, isTrue);
    });

    test('no artist at all is unknown, not various', () {
      final album = _only([_track('a', album: 'A')]);

      expect(album.artist, isNull);
      expect(album.variousArtists, isFalse);
    });

    test('songs without an album share "Unknown album"', () {
      final albums = groupAlbums([
        _track('a', artist: 'X', albumArtist: 'P'),
        _track('b', artist: 'Y', albumArtist: 'Q'),
        _track('c', album: 'A'),
      ]);

      final unknown = albums.singleWhere((a) => a.title == null);
      expect(unknown.tracks, hasLength(2));
      expect(unknown.id, const AlbumId(null));
    });

    test('the same name by different album artists is two albums', () {
      final albums = groupAlbums([
        _track('a', album: 'Mezmur', albumArtist: 'P'),
        _track('b', album: 'Mezmur', albumArtist: 'Q'),
      ]);

      expect(albums, hasLength(2));
    });
  });

  group('AlbumId', () {
    test('round-trips through route query parameters', () {
      for (final id in const [
        AlbumId('Mezmur Vol. 1', 'ዘማሪት'),
        AlbumId('A & B / C'),
        AlbumId(null),
      ]) {
        expect(AlbumId.fromQuery(id.toQuery()), id);
      }
    });

    test('the unknown album ignores the album artist', () {
      expect(const AlbumId(null, 'P'), const AlbumId(null));
    });

    test('a query without an album is no id', () {
      expect(AlbumId.fromQuery(const {}), isNull);
    });
  });

  group('sortAlbums', () {
    final albums = groupAlbums([
      _track('a', album: 'Beta', artist: 'Zed', year: 2010),
      _track('b', album: 'alpha', artist: 'Amy', year: 2020),
      _track('c', album: 'Gamma', artist: 'X'),
      _track('d', album: 'Gamma', artist: 'Y'),
      _track('e'),
    ]);

    List<String?> titles(AlbumSort sort) => [
      for (final a in sortAlbums(albums, sort)) a.title,
    ];

    test('by name, unknown last both ways', () {
      expect(titles(const AlbumSort(AlbumSortField.name)), [
        'alpha',
        'Beta',
        'Gamma',
        null,
      ]);
      expect(titles(const AlbumSort(AlbumSortField.name, descending: true)), [
        'Gamma',
        'Beta',
        'alpha',
        null,
      ]);
    });

    test('by artist; various and unknown last, then by name', () {
      expect(titles(const AlbumSort(AlbumSortField.artist)), [
        'alpha',
        'Beta',
        'Gamma',
        null,
      ]);
      expect(titles(const AlbumSort(AlbumSortField.artist, descending: true)), [
        'Beta',
        'alpha',
        'Gamma',
        null,
      ]);
    });

    test('by year; no year last, then by name', () {
      expect(titles(const AlbumSort(AlbumSortField.year)), [
        'Beta',
        'alpha',
        'Gamma',
        null,
      ]);
      expect(titles(const AlbumSort(AlbumSortField.year, descending: true)), [
        'alpha',
        'Beta',
        'Gamma',
        null,
      ]);
    });
  });
}
