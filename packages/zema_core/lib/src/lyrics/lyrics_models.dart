import '../failures.dart';

/// What part of a song a section is.
enum SectionKind { verse, chorus, bridge, other }

/// One written line, with how it reads in Latin letters when known.
class LyricLine {
  const LyricLine(this.text, {this.transliteration});

  factory LyricLine.fromJson(Object? json) {
    final map = _map(json, 'line');
    return LyricLine(
      _string(map, 'text'),
      transliteration: _optionalString(map, 'transliteration'),
    );
  }

  final String text;
  final String? transliteration;

  Map<String, Object?> toJson() => {
    'text': text,
    'transliteration': ?transliteration,
  };

  @override
  bool operator ==(Object other) =>
      other is LyricLine &&
      other.text == text &&
      other.transliteration == transliteration;

  @override
  int get hashCode => Object.hash(text, transliteration);

  @override
  String toString() => 'LyricLine($text)';
}

/// A verse, chorus or bridge, written once however often it is sung.
class LyricSection {
  const LyricSection({
    required this.id,
    required this.kind,
    required this.lines,
  });

  factory LyricSection.fromJson(Object? json) {
    final map = _map(json, 'section');
    final kind = _string(map, 'kind');
    return LyricSection(
      id: _string(map, 'id'),
      kind:
          SectionKind.values.asNameMap()[kind] ??
          (throw LyricsFormatFailure('Unknown section kind "$kind"')),
      lines: [for (final l in _list(map, 'lines')) LyricLine.fromJson(l)],
    );
  }

  /// Unique within its song; the play order refers to it.
  final String id;
  final SectionKind kind;
  final List<LyricLine> lines;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'lines': [for (final l in lines) l.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is LyricSection &&
      other.id == id &&
      other.kind == kind &&
      _listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(id, kind, Object.hashAll(lines));

  @override
  String toString() => 'LyricSection($id, ${kind.name}, ${lines.length})';
}

/// A song's canonical text: its sections and the order they are sung in.
/// What a song is known by: enough to match tracks and find it by title.
/// Both a full [Song] and a catalog index entry have it.
abstract interface class SongIdentity {
  String get id;
  String get title;

  /// The title in Latin letters, when known.
  String? get transliteration;
  String? get artist;
}

class Song implements SongIdentity {
  const Song({
    required this.id,
    required this.title,
    required this.sections,
    this.playOrder = const [],
    this.transliteration,
    this.artist,
    this.album,
  });

  factory Song.fromJson(Object? json) {
    final map = _map(json, 'song');
    return Song(
      id: _string(map, 'id'),
      title: _string(map, 'title'),
      transliteration: _optionalString(map, 'transliteration'),
      artist: _optionalString(map, 'artist'),
      album: _optionalString(map, 'album'),
      sections: [
        for (final s in _list(map, 'sections')) LyricSection.fromJson(s),
      ],
      playOrder: [
        for (final id in _optionalList(map, 'playOrder'))
          id is String
              ? id
              : throw const LyricsFormatFailure(
                  '"playOrder" must list section IDs',
                ),
      ],
    );
  }

  @override
  final String id;
  @override
  final String title;
  @override
  final String? transliteration;
  @override
  final String? artist;
  final String? album;
  final List<LyricSection> sections;

  /// Section IDs in the order they are sung, repeats included. Empty means
  /// every section once, as written.
  final List<String> playOrder;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'transliteration': ?transliteration,
    'artist': ?artist,
    'album': ?album,
    'sections': [for (final s in sections) s.toJson()],
    if (playOrder.isNotEmpty) 'playOrder': playOrder,
  };

  @override
  bool operator ==(Object other) =>
      other is Song &&
      other.id == id &&
      other.title == title &&
      other.transliteration == transliteration &&
      other.artist == artist &&
      other.album == album &&
      _listEquals(other.sections, sections) &&
      _listEquals(other.playOrder, playOrder);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    transliteration,
    artist,
    album,
    Object.hashAll(sections),
    Object.hashAll(playOrder),
  );

  @override
  String toString() => 'Song($id, $title)';
}

/// Where a recording can be played from.
enum RecordingSource { bundled, localFile, youtube, telegram }

/// One performance of a song, which its timing belongs to.
class Recording {
  const Recording({
    required this.id,
    required this.songId,
    required this.source,
    this.artist,
    this.duration,
    this.offset = Duration.zero,
  });

  factory Recording.fromJson(Object? json) {
    final map = _map(json, 'recording');
    final source = _string(map, 'source');
    final durationMs = _optionalInt(map, 'durationMs');
    return Recording(
      id: _string(map, 'id'),
      songId: _string(map, 'songId'),
      source:
          RecordingSource.values.asNameMap()[source] ??
          (throw LyricsFormatFailure('Unknown recording source "$source"')),
      artist: _optionalString(map, 'artist'),
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      offset: Duration(milliseconds: _optionalInt(map, 'offsetMs') ?? 0),
    );
  }

  final String id;
  final String songId;
  final RecordingSource source;
  final String? artist;
  final Duration? duration;

  /// Shifts this recording's timing; positive shows lines later. The
  /// listener's own adjustment adds to it.
  final Duration offset;

  Map<String, Object?> toJson() => {
    'id': id,
    'songId': songId,
    'source': source.name,
    'artist': ?artist,
    'durationMs': ?duration?.inMilliseconds,
    if (offset != Duration.zero) 'offsetMs': offset.inMilliseconds,
  };

  @override
  bool operator ==(Object other) =>
      other is Recording &&
      other.id == id &&
      other.songId == songId &&
      other.source == source &&
      other.artist == artist &&
      other.duration == duration &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(id, songId, source, artist, duration, offset);

  @override
  String toString() => 'Recording($id of $songId)';
}

/// When each sung line starts in one recording: one start per line of the
/// expanded play order (see `expandPlayOrder`).
class SyncTiming {
  const SyncTiming({required this.recordingId, required this.starts});

  factory SyncTiming.fromJson(Object? json) {
    final map = _map(json, 'timing');
    return SyncTiming(
      recordingId: _string(map, 'recordingId'),
      starts: [
        for (final ms in _list(map, 'startsMs'))
          ms is int
              ? Duration(milliseconds: ms)
              : throw const LyricsFormatFailure(
                  '"startsMs" must list milliseconds',
                ),
      ],
    );
  }

  final String recordingId;
  final List<Duration> starts;

  Map<String, Object?> toJson() => {
    'recordingId': recordingId,
    'startsMs': [for (final s in starts) s.inMilliseconds],
  };

  @override
  bool operator ==(Object other) =>
      other is SyncTiming &&
      other.recordingId == recordingId &&
      _listEquals(other.starts, starts);

  @override
  int get hashCode => Object.hash(recordingId, Object.hashAll(starts));

  @override
  String toString() => 'SyncTiming($recordingId, ${starts.length} lines)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Map<String, Object?> _map(Object? json, String what) => json is Map
    ? json.cast<String, Object?>()
    : throw LyricsFormatFailure('A $what must be a JSON object');

String _string(Map<String, Object?> map, String key) => switch (map[key]) {
  final String value => value,
  _ => throw LyricsFormatFailure('"$key" must be a string'),
};

String? _optionalString(Map<String, Object?> map, String key) =>
    switch (map[key]) {
      null => null,
      final String value => value,
      _ => throw LyricsFormatFailure('"$key" must be a string'),
    };

int? _optionalInt(Map<String, Object?> map, String key) => switch (map[key]) {
  null => null,
  final int value => value,
  _ => throw LyricsFormatFailure('"$key" must be a whole number'),
};

List<Object?> _list(Map<String, Object?> map, String key) => switch (map[key]) {
  final List<Object?> value => value,
  _ => throw LyricsFormatFailure('"$key" must be a list'),
};

List<Object?> _optionalList(Map<String, Object?> map, String key) =>
    map[key] == null ? const [] : _list(map, key);
