import 'dart:async';

import 'package:zema_core/zema_core.dart';

/// A catalog served from memory. By default its index lists the songs of a
/// [LyricsRepository] (the sample fixtures in app tests) and serves their
/// documents, so tracks link and lyrics download as they would against the
/// real backend.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({List<CatalogEntry>? entries, this.lyrics})
    // ignore: prefer_initializing_formals (the public name is [entries]).
    : _entries = entries;

  List<CatalogEntry>? _entries;

  /// The index given (or set), returned by [index] instead of one built
  /// from [lyrics].
  List<CatalogEntry> get entries => _entries ?? const [];
  set entries(List<CatalogEntry> entries) => _entries = entries;

  /// Serves its songs' documents, and lists them as the index unless
  /// [entries] were given.
  final LyricsRepository? lyrics;

  /// Thrown by every call when set.
  ZemaFailure? failure;

  /// The version each song has in the index built from [lyrics] (1 when
  /// not listed).
  final versions = <String, int>{};

  /// How many times [index] was called.
  var indexCalls = 0;

  /// The IDs passed to [song], in order.
  final songCalls = <String>[];

  /// When set, [song] waits for it before answering.
  Completer<void>? songGate;

  @override
  Future<List<CatalogEntry>> index() async {
    indexCalls++;
    if (failure case final failure?) throw failure;
    final lyrics = this.lyrics;
    if (_entries case final entries?) return entries;
    if (lyrics == null) return const [];
    return [
      for (final song in await lyrics.songs())
        catalogEntry(song, version: versions[song.id] ?? 1),
    ];
  }

  @override
  Future<SongDocument?> song(String id) async {
    songCalls.add(id);
    await songGate?.future;
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
