import '../failures.dart';
import 'lyrics_models.dart';
import 'sync_engine.dart';

/// A line of LRC text the importer couldn't use.
class LrcSkippedLine {
  const LrcSkippedLine(this.lineNumber, this.text);

  /// 1-based, as an editor shows it.
  final int lineNumber;
  final String text;

  @override
  String toString() => 'line $lineNumber: $text';
}

/// What [importLrc] made of an LRC file.
class LrcImport {
  const LrcImport({
    required this.song,
    required this.recording,
    required this.timing,
    required this.skipped,
  });

  final Song song;
  final Recording recording;
  final SyncTiming timing;
  final List<LrcSkippedLine> skipped;
}

final _timeTag = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');
final _infoTag = RegExp(r'^\[([a-zA-Z]+):(.*)\]$');

/// Reads LRC text ("[01:23.45] a line") into a song, one recording of it
/// and that recording's timing.
///
/// - A line with several time tags is sung at each time; lines are put in
///   time order.
/// - `[ti:]`, `[ar:]` and `[al:]` set title, artist and album; `[offset:]`
///   (milliseconds, positive shows lines earlier) sets the recording's
///   offset; `[tr:]` right after a timed line is that line's
///   transliteration.
/// - The longest block of two or more lines sung at least twice becomes a
///   chorus, written once; the lines between its repeats become verses.
/// - Lines that are neither timed nor a known tag, and timed lines with no
///   text, are skipped and listed in [LrcImport.skipped].
///
/// Throws [LyricsFormatFailure] when there is no timed line at all.
LrcImport importLrc(
  String text, {
  required String songId,
  required String recordingId,
  RecordingSource source = RecordingSource.bundled,
}) {
  final timed = <(Duration, LyricLine)>[];
  final skipped = <LrcSkippedLine>[];
  final info = <String, String>{};
  var offsetMs = 0;
  // Lines of the last timed text, to attach a following [tr:] to.
  var lastIndexes = <int>[];

  for (final (i, raw) in text.split(RegExp(r'\r?\n')).indexed) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final times = _timeTag.allMatches(line).toList();
    if (times.isNotEmpty && times.first.start == 0) {
      final lyric = line.substring(times.last.end).trim();
      if (lyric.isEmpty) {
        skipped.add(LrcSkippedLine(i + 1, raw));
        lastIndexes = [];
        continue;
      }
      lastIndexes = [];
      for (final match in times) {
        lastIndexes.add(timed.length);
        timed.add((_time(match), LyricLine(lyric)));
      }
      continue;
    }
    final tag = _infoTag.firstMatch(line);
    if (tag == null) {
      skipped.add(LrcSkippedLine(i + 1, raw));
      continue;
    }
    final key = tag.group(1)!.toLowerCase();
    final value = tag.group(2)!.trim();
    switch (key) {
      case 'tr' when lastIndexes.isNotEmpty:
        for (final index in lastIndexes) {
          final (start, line) = timed[index];
          timed[index] = (start, LyricLine(line.text, transliteration: value));
        }
      case 'offset':
        final ms = int.tryParse(value.replaceFirst('+', ''));
        if (ms == null) {
          skipped.add(LrcSkippedLine(i + 1, raw));
        } else {
          offsetMs = ms;
        }
      case 'ti' || 'ar' || 'al':
        info[key] = value;
      default:
        // Other LRC tags (length, by, re, ve …) and a stray [tr:] are
        // ignored, as players do.
        break;
    }
  }
  if (timed.isEmpty) {
    throw LyricsFormatFailure('No timed lines in the LRC for $songId');
  }

  // Stable sort keeps file order for lines starting together.
  final ordered = [...timed.indexed]
    ..sort((a, b) {
      final byTime = a.$2.$1.compareTo(b.$2.$1);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  final lines = [for (final (_, (_, line)) in ordered) line];
  final (sections, playOrder) = _sections(lines);

  return LrcImport(
    song: Song(
      id: songId,
      title: info['ti'] ?? songId,
      artist: info['ar'],
      album: info['al'],
      sections: sections,
      playOrder: playOrder,
    ),
    recording: Recording(
      id: recordingId,
      songId: songId,
      source: source,
      artist: info['ar'],
      // LRC's positive offset shows lines earlier; Zema's shows them later.
      offset: Duration(milliseconds: -offsetMs),
    ),
    timing: SyncTiming(
      recordingId: recordingId,
      starts: [for (final (_, (start, _)) in ordered) start],
    ),
    skipped: skipped,
  );
}

Duration _time(RegExpMatch match) {
  final fraction = match.group(3) ?? '0';
  // ".5" is half a second, ".45" 450 ms, ".456" 456 ms.
  final ms = int.parse(fraction.padRight(3, '0'));
  return Duration(
    minutes: int.parse(match.group(1)!),
    seconds: int.parse(match.group(2)!),
    milliseconds: ms,
  );
}

/// Splits sung lines into sections: the longest block of two or more lines
/// sung at least twice (without overlapping) is the chorus; the runs of
/// other lines become verses.
(List<LyricSection>, List<String>) _sections(List<LyricLine> lines) {
  final chorus = _repeatedBlock(lines);
  final sections = <LyricSection>[];
  final playOrder = <String>[];
  var verse = <LyricLine>[];
  void endVerse() {
    if (verse.isEmpty) return;
    final id =
        'v${sections.where((s) => s.kind == SectionKind.verse).length + 1}';
    sections.add(LyricSection(id: id, kind: SectionKind.verse, lines: verse));
    playOrder.add(id);
    verse = [];
  }

  var i = 0;
  while (i < lines.length) {
    if (chorus != null && _blockAt(lines, i, chorus)) {
      endVerse();
      if (!sections.any((s) => s.id == 'c')) {
        sections.add(
          LyricSection(id: 'c', kind: SectionKind.chorus, lines: chorus),
        );
      }
      playOrder.add('c');
      i += chorus.length;
    } else {
      verse.add(lines[i++]);
    }
  }
  endVerse();
  return (sections, playOrder);
}

List<LyricLine>? _repeatedBlock(List<LyricLine> lines) {
  for (var length = lines.length ~/ 2; length >= 2; length--) {
    for (var start = 0; start + length <= lines.length; start++) {
      final block = lines.sublist(start, start + length);
      var count = 0;
      var i = 0;
      while (i + length <= lines.length) {
        if (_blockAt(lines, i, block)) {
          count++;
          i += length;
        } else {
          i++;
        }
      }
      if (count >= 2) return block;
    }
  }
  return null;
}

/// Whether [block] is sung starting at [at], comparing the text only (a
/// repeat may lack the transliteration line).
bool _blockAt(List<LyricLine> lines, int at, List<LyricLine> block) {
  if (at + block.length > lines.length) return false;
  for (var j = 0; j < block.length; j++) {
    if (lines[at + j].text != block[j].text) return false;
  }
  return true;
}

/// A song as the catalog stores it: the song, one recording and its timing.
class CatalogSong {
  const CatalogSong({
    required this.song,
    required this.recording,
    required this.timing,
    this.skipped = const [],
  });

  final Song song;
  final Recording recording;
  final SyncTiming timing;

  /// LRC lines the importer couldn't use.
  final List<LrcSkippedLine> skipped;

  /// The catalog's document for this song (the backend's `get_song`).
  Map<String, Object?> toDocument() => {
    'song': song.toJson(),
    'recordings': [recording.toJson()],
    'timings': [timing.toJson()],
  };
}

/// One entry of a lyrics index (`{"id", "file", "transliteration"?,
/// "durationMs"?}`) with the LRC text of its file: the song, recorded once,
/// with the recording's ID equal to the song's.
///
/// Throws [LyricsFormatFailure] when the entry lacks an ID or file, the LRC
/// has no timed lines, or the timing doesn't fit the sung lines.
CatalogSong importIndexedLrc(
  Map<String, Object?> entry,
  String lrc, {
  RecordingSource source = RecordingSource.bundled,
}) {
  final id = switch (entry) {
    {'id': final String id, 'file': String _} => id,
    _ => throw const LyricsFormatFailure('An index entry needs id and file'),
  };
  final imported = importLrc(lrc, songId: id, recordingId: id, source: source);
  // Throws when the timing doesn't fit the lines.
  SyncedLyrics.of(imported.song, imported.timing);
  final song = imported.song;
  final recording = imported.recording;
  final durationMs = entry['durationMs'];
  return CatalogSong(
    song: Song(
      id: song.id,
      title: song.title,
      transliteration: entry['transliteration'] as String?,
      artist: song.artist,
      album: song.album,
      sections: song.sections,
      playOrder: song.playOrder,
    ),
    recording: Recording(
      id: recording.id,
      songId: recording.songId,
      source: recording.source,
      artist: recording.artist,
      duration: durationMs is int ? Duration(milliseconds: durationMs) : null,
      offset: recording.offset,
    ),
    timing: imported.timing,
    skipped: imported.skipped,
  );
}
