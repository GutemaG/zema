// Editing the starts of a song's sung lines, one per line occurrence; null
// for lines not tapped yet. Starts always rise from line to line.

/// The smallest gap kept between two lines' starts.
const minLineGap = Duration(milliseconds: 100);

/// How far before a line "Redo from here" starts playing.
const redoLeadIn = Duration(seconds: 3);

/// The line the next tap times: the first not timed yet; null when all are.
int? nextUntimed(List<Duration?> starts) {
  final i = starts.indexOf(null);
  return i < 0 ? null : i;
}

/// [starts] fitted to [count] lines: kept when the count is the same,
/// otherwise all untimed (the lyrics changed).
List<Duration?> startsFor(List<Duration?> starts, int count) =>
    starts.length == count ? starts : List<Duration?>.filled(count, null);

/// Times the next line at [position]. Unchanged after the last line, or
/// when [position] isn't [minLineGap] after the line before (the recording
/// was moved back).
List<Duration?> tapNext(List<Duration?> starts, Duration position) {
  final i = nextUntimed(starts);
  if (i == null) return starts;
  final previous = _previous(starts, i);
  if (previous != null && position < previous + minLineGap) return starts;
  return [...starts]..[i] = position;
}

/// Clears the last line timed; unchanged when none is.
List<Duration?> undoLastTap(List<Duration?> starts) {
  final i = starts.lastIndexWhere((s) => s != null);
  if (i < 0) return starts;
  return [...starts]..[i] = null;
}

/// Moves line [index]'s start by [by], keeping [minLineGap] from the timed
/// lines around it and not before zero.
List<Duration?> nudgeStart(List<Duration?> starts, int index, Duration by) {
  final start = starts[index];
  if (start == null) return starts;
  final previous = _previous(starts, index);
  final next = _following(starts, index);
  var moved = start + by;
  final low = previous == null ? Duration.zero : previous + minLineGap;
  if (moved < low) moved = low;
  if (next != null && moved > next - minLineGap) moved = next - minLineGap;
  if (moved < low) return starts;
  return [...starts]..[index] = moved;
}

/// Clears line [index] and every line after it.
List<Duration?> redoFrom(List<Duration?> starts, int index) => [
  for (var i = 0; i < starts.length; i++) i < index ? starts[i] : null,
];

/// Where playback restarts for "Redo from here" on line [index]:
/// [redoLeadIn] before its old start (or the start before it), not before
/// zero.
Duration redoPosition(List<Duration?> starts, int index) {
  final from = starts[index] ?? _previous(starts, index) ?? Duration.zero;
  final at = from - redoLeadIn;
  return at < Duration.zero ? Duration.zero : at;
}

Duration? _previous(List<Duration?> starts, int index) {
  for (var i = index - 1; i >= 0; i--) {
    if (starts[i] case final start?) return start;
  }
  return null;
}

Duration? _following(List<Duration?> starts, int index) {
  for (var i = index + 1; i < starts.length; i++) {
    if (starts[i] case final start?) return start;
  }
  return null;
}

/// The line sung at [position]: the last timed line starting at or before
/// it; null before the first.
int? lineAt(List<Duration?> starts, Duration position) {
  int? line;
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    if (start != null && start <= position) line = i;
  }
  return line;
}
