import '../failures.dart';
import 'lyrics_models.dart';
import 'play_order.dart';

/// Which sung lines a playback position falls on.
class SyncPosition {
  const SyncPosition({required this.current, required this.next});

  /// The line being sung, or null before the first line starts.
  final int? current;

  /// The line after it, or null after the last line.
  final int? next;

  @override
  bool operator ==(Object other) =>
      other is SyncPosition && other.current == current && other.next == next;

  @override
  int get hashCode => Object.hash(current, next);

  @override
  String toString() => 'SyncPosition(current: $current, next: $next)';
}

/// Finds the line being sung from a playback position.
///
/// Holds no playback state: every call looks the position up afresh, so
/// seeking either way needs nothing special.
class SyncEngine {
  /// [starts] are the lines' start times in sung order; they must not go
  /// backwards.
  SyncEngine(List<Duration> starts) : _starts = List.unmodifiable(starts) {
    for (var i = 1; i < _starts.length; i++) {
      if (_starts[i] < _starts[i - 1]) {
        throw LyricsFormatFailure(
          'Line $i starts at ${_starts[i]}, before line ${i - 1} '
          '(${_starts[i - 1]})',
        );
      }
    }
  }

  final List<Duration> _starts;

  int get lineCount => _starts.length;

  /// The lines at [position]. [offset] shifts the timing: positive shows
  /// every line later.
  SyncPosition at(Duration position, {Duration offset = Duration.zero}) {
    final time = position - offset;
    // The last line starting at or before [time]; binary search.
    var low = 0;
    var high = _starts.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_starts[mid] <= time) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    final current = low - 1;
    return SyncPosition(
      current: current < 0 ? null : current,
      next: low < _starts.length ? low : null,
    );
  }

  /// Where to seek so line [index] is being sung, with the same [offset].
  Duration startOf(int index, {Duration offset = Duration.zero}) {
    final start = _starts[index] + offset;
    return start < Duration.zero ? Duration.zero : start;
  }
}

/// A song, its sung lines and one recording's timing for them, checked to
/// fit together.
class SyncedLyrics {
  SyncedLyrics._(this.song, this.lines, this.engine);

  /// Throws [LyricsFormatFailure] when [timing] doesn't have exactly one
  /// start per sung line, or its starts go backwards. With [partial],
  /// [timing] may time only the first lines (lyrics still being synced); the
  /// lines after them are never current.
  factory SyncedLyrics.of(
    Song song,
    SyncTiming timing, {
    bool partial = false,
  }) {
    final lines = expandPlayOrder(song).occurrences;
    if (partial
        ? timing.starts.length > lines.length
        : timing.starts.length != lines.length) {
      throw LyricsFormatFailure(
        'Timing ${timing.recordingId} has ${timing.starts.length} starts '
        'for ${lines.length} sung lines of ${song.id}',
      );
    }
    return SyncedLyrics._(song, lines, SyncEngine(timing.starts));
  }

  final Song song;
  final List<LineOccurrence> lines;
  final SyncEngine engine;

  /// Whether line [index] has a start (all do unless partial).
  bool isTimed(int index) => index < engine.lineCount;
}
