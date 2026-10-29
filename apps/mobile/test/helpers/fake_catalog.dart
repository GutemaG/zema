import 'package:zema_core/zema_core.dart';

/// A catalog served from memory. By default its index lists the songs of a
/// [LyricsRepository] (the bundled samples in app tests), so tracks link as
/// they would against the real backend.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({List<CatalogEntry>? entries, this.lyrics})
    : entries = entries ?? [];

  /// The index returned by [index] when [lyrics] is null.
  List<CatalogEntry> entries;

  /// When set, [index] lists its songs instead of [entries].
  final LyricsRepository? lyrics;

  /// Thrown by every call when set.
  ZemaFailure? failure;

  /// How many times [index] was called.
  var indexCalls = 0;

  @override
  Future<List<CatalogEntry>> index() async {
    indexCalls++;
    if (failure case final failure?) throw failure;
    final lyrics = this.lyrics;
    if (lyrics == null) return entries;
    return [for (final song in await lyrics.songs()) catalogEntry(song)];
  }

  @override
  Future<SongDocument?> song(String id) async {
    if (failure case final failure?) throw failure;
    final lyrics = this.lyrics;
    final song = await lyrics?.song(id);
    if (lyrics == null || song == null) return null;
    final recordings = await lyrics.recordings(id);
    return SongDocument(
      song: song,
      recordings: recordings,
      timings: [for (final r in recordings) ?await lyrics.timing(r.id)],
    );
  }

  @override
  Future<List<CatalogSearchHit>> search(String query) async {
    if (failure case final failure?) throw failure;
    return const [];
  }

  @override
  Future<void> report({
    required String songId,
    required ReportReason reason,
    required String installId,
    String? recordingId,
    String? note,
  }) async {
    if (failure case final failure?) throw failure;
  }
}

/// [song] as an index entry.
CatalogEntry catalogEntry(
  SongIdentity song, {
  bool synced = true,
  int version = 1,
  String? album,
}) => CatalogEntry(
  id: song.id,
  title: song.title,
  transliteration: song.transliteration,
  artist: song.artist,
  album: album,
  synced: synced,
  version: version,
  approvedAt: DateTime.utc(2026, 10, 29),
);
