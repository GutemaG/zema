import '../failures.dart';
import '../lyrics/lyrics_models.dart';

/// One approved song in the catalog's index: enough to link tracks and find
/// songs by title, without the lyrics.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.title,
    required this.synced,
    required this.version,
    required this.approvedAt,
    this.transliteration,
    this.artist,
    this.album,
  });

  final String id;
  final String title;
  final String? transliteration;
  final String? artist;
  final String? album;

  /// Whether a recording of the song has a timing.
  final bool synced;

  /// Grows whenever the song's lyrics, recordings or timings change.
  final int version;
  final DateTime approvedAt;

  @override
  bool operator ==(Object other) =>
      other is CatalogEntry &&
      other.id == id &&
      other.title == title &&
      other.transliteration == transliteration &&
      other.artist == artist &&
      other.album == album &&
      other.synced == synced &&
      other.version == version &&
      other.approvedAt == approvedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    transliteration,
    artist,
    album,
    synced,
    version,
    approvedAt,
  );

  @override
  String toString() => 'CatalogEntry($id v$version)';
}

/// A song with its recordings and their timings, as the catalog serves it.
class SongDocument {
  const SongDocument({
    required this.song,
    this.recordings = const [],
    this.timings = const [],
  });

  /// Parses `{"song", "recordings"?, "timings"?}` (see `CatalogSong.toDocument`).
  ///
  /// Throws [LyricsFormatFailure] when it is malformed.
  factory SongDocument.fromJson(Object? json) {
    if (json is! Map) {
      throw const LyricsFormatFailure('A song document must be a JSON object');
    }
    List<Object?> list(String key) => switch (json[key]) {
      null => const [],
      final List<Object?> value => value,
      _ => throw LyricsFormatFailure('"$key" must be a list'),
    };
    return SongDocument(
      song: Song.fromJson(json['song']),
      recordings: [for (final r in list('recordings')) Recording.fromJson(r)],
      timings: [for (final t in list('timings')) SyncTiming.fromJson(t)],
    );
  }

  final Song song;
  final List<Recording> recordings;
  final List<SyncTiming> timings;

  Map<String, Object?> toJson() => {
    'song': song.toJson(),
    'recordings': [for (final r in recordings) r.toJson()],
    'timings': [for (final t in timings) t.toJson()],
  };

  @override
  String toString() => 'SongDocument(${song.id})';
}

/// A song the catalog found for a search, by its title or one of its lines.
class CatalogSearchHit {
  const CatalogSearchHit({
    required this.songId,
    required this.title,
    required this.score,
    this.transliteration,
    this.artist,
    this.line,
    this.lineTransliteration,
  });

  final String songId;
  final String title;
  final String? transliteration;
  final String? artist;
  final double score;

  /// The best-matching line, or null when the title matched.
  final String? line;
  final String? lineTransliteration;

  @override
  String toString() =>
      'CatalogSearchHit($songId${line == null ? '' : ': $line'})';
}

/// Why a listener reports a song's lyrics.
enum ReportReason { wrongWords, wrongTiming, wrongSong, other }

/// The shared lyrics catalog. Implementations throw [ZemaFailure]s only.
abstract interface class CatalogRepository {
  /// Every approved song.
  Future<List<CatalogEntry>> index();

  /// The approved song [id] with its recordings and timings, or null.
  Future<SongDocument?> song(String id);

  /// Approved songs matching [query] by title or a lyric line, best first.
  Future<List<CatalogSearchHit>> search(String query);

  /// Reports song [songId]'s lyrics for moderators. [installId] identifies
  /// this install for the daily limit ([RateLimitFailure] past it).
  Future<void> report({
    required String songId,
    required ReportReason reason,
    required String installId,
    String? recordingId,
    String? note,
  });
}
