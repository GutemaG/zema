import 'package:zema_core/zema_core.dart';

/// Lyrics held in memory: songs, their recordings and the timings of some
/// of them. Served through a `FakeCatalogRepository`, its songs make up the
/// catalog.
class MemoryLyricsRepository implements LyricsRepository {
  MemoryLyricsRepository(
    this._songs, {
    List<Recording> recordings = const [],
    List<SyncTiming> timings = const [],
  }) : _allRecordings = recordings,
       _allTimings = timings;

  final List<Song> _songs;
  final List<Recording> _allRecordings;
  final List<SyncTiming> _allTimings;

  @override
  Future<List<Song>> songs() async => _songs;

  @override
  Future<Song?> song(String id) async =>
      _songs.where((s) => s.id == id).firstOrNull;

  @override
  Future<List<Recording>> recordings(String songId) async => [
    for (final r in _allRecordings)
      if (r.songId == songId) r,
  ];

  @override
  Future<SyncTiming?> timing(String recordingId) async =>
      _allTimings.where((t) => t.recordingId == recordingId).firstOrNull;

  @override
  Future<List<Song>> search(String query) async => searchSongs(_songs, query);
}
