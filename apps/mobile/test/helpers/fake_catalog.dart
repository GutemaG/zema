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

  /// What [search] answers, by query (nothing for other queries).
  final searchHits = <String, List<CatalogSearchHit>>{};

  /// The queries passed to [search], in order.
  final searchCalls = <String>[];

  /// When set, [search] waits for it before answering.
  Completer<void>? searchGate;

  /// The reports accepted by [report], in order.
  final reports = <FakeReport>[];

  /// Thrown by [report] for that song (after [failure]).
  final reportFailures = <String, ZemaFailure>{};

  /// How many times [report] was called, accepted or not.
  var reportCalls = 0;

  /// The report IDs passed to [report], accepted or not, in order.
  final reportIds = <String?>[];

  /// When set, [report] waits for it before answering.
  Completer<void>? reportGate;

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
    searchCalls.add(query);
    await searchGate?.future;
    if (failure case final failure?) throw failure;
    return searchHits[query] ?? const [];
  }

  @override
  Future<void> report({
    required String songId,
    required ReportReason reason,
    required String installId,
    String? recordingId,
    String? note,
    String? reportId,
  }) async {
    reportCalls++;
    reportIds.add(reportId);
    await reportGate?.future;
    if (failure case final failure?) throw failure;
    if (reportFailures[songId] case final failure?) throw failure;
    reports.add((
      songId: songId,
      reason: reason,
      installId: installId,
      recordingId: recordingId,
      note: note,
      reportId: reportId,
    ));
  }
}

/// A report [FakeCatalogRepository] accepted.
typedef FakeReport = ({
  String songId,
  ReportReason reason,
  String installId,
  String? recordingId,
  String? note,
  String? reportId,
});

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
