/// A frame of a lyrics clip: lyric [line] (null before the first line) shown
/// from [at], counted from the clip's start.
typedef ClipFrameTime = ({int? line, Duration at});

/// One frame per line change in the clip from [start] to [end]: the line
/// sung at [start] from zero, then each line that starts inside the clip.
/// [starts] are the lines' start times in the audio, in order.
List<ClipFrameTime> clipFrameTimes(
  List<Duration> starts,
  Duration start,
  Duration end,
) {
  int? at(Duration t) {
    int? found;
    for (final (i, s) in starts.indexed) {
      if (s > t) break;
      found = i;
    }
    return found;
  }

  final frames = <ClipFrameTime>[(line: at(start), at: Duration.zero)];
  for (final (i, s) in starts.indexed) {
    if (s <= start) continue;
    if (s >= end) break;
    frames.add((line: i, at: s - start));
  }
  return frames;
}
