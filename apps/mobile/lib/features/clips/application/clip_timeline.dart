import '../data/clip_encoder.dart' show maxClipLength;

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

/// The usual clip length.
const defaultClipLength = Duration(seconds: 60);

/// Where a new clip starts and ends: from the line sung at [position] (the
/// track playing now), else a second before the first line, for
/// [defaultClipLength] or to the end of a shorter track.
({Duration start, Duration end}) defaultClipRange(
  List<Duration> starts,
  Duration length, {
  Duration? position,
}) {
  Duration start;
  if (position != null && position > Duration.zero) {
    start = position;
    for (final s in starts) {
      if (s > position) break;
      start = s;
    }
  } else if (starts.isNotEmpty) {
    start = starts.first - const Duration(seconds: 1);
  } else {
    start = Duration.zero;
  }
  if (length > Duration.zero && start + defaultClipLength > length) {
    start = length - defaultClipLength;
  }
  if (start < Duration.zero) start = Duration.zero;
  var end = start + defaultClipLength;
  if (length > Duration.zero && end > length) end = length;
  return (start: start, end: end);
}

/// The shortest clip that can be made.
const minClipLength = Duration(seconds: 5);

/// [t] moved to the nearest of [starts] within [reach], else as it is.
Duration snapToLine(
  List<Duration> starts,
  Duration t, {
  Duration reach = const Duration(seconds: 2),
}) {
  Duration? best;
  for (final s in starts) {
    if ((s - t).abs() <= reach &&
        (best == null || (s - t).abs() < (best - t).abs())) {
      best = s;
    }
  }
  return best ?? t;
}

/// The line start after (or with [forward] false, before) [t]; a second on
/// when there are no lines.
Duration stepToLine(
  List<Duration> starts,
  Duration t, {
  required bool forward,
}) {
  const tolerance = Duration(milliseconds: 50);
  if (forward) {
    for (final s in starts) {
      if (s > t + tolerance) return s;
    }
    return starts.isEmpty ? t + const Duration(seconds: 1) : t;
  }
  for (final s in starts.reversed) {
    if (s < t - tolerance) return s;
  }
  return starts.isEmpty ? t - const Duration(seconds: 1) : Duration.zero;
}

/// [start] to [end] kept inside the track's [length], between
/// [minClipLength] and [maxClipLength] long. The handle not [movedStart]
/// gives way first.
({Duration start, Duration end}) clampClipRange(
  Duration start,
  Duration end,
  Duration length, {
  required bool movedStart,
}) {
  Duration clamp(Duration t) => t < Duration.zero
      ? Duration.zero
      : (length > Duration.zero && t > length ? length : t);
  start = clamp(start);
  end = clamp(end);
  if (movedStart) {
    if (end - start < minClipLength) end = clamp(start + minClipLength);
    if (end - start > maxClipLength) end = start + maxClipLength;
    if (end - start < minClipLength) start = clamp(end - minClipLength);
  } else {
    if (end - start < minClipLength) start = clamp(end - minClipLength);
    if (end - start > maxClipLength) start = end - maxClipLength;
    if (end - start < minClipLength) end = clamp(start + minClipLength);
  }
  return (start: start, end: end);
}
