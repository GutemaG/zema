final _duration = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{2})$');

/// A duration typed as m:ss or h:mm:ss; null when [text] isn't one, or is
/// zero.
Duration? parseDurationText(String text) {
  final match = _duration.firstMatch(text.trim());
  if (match == null) return null;
  final hours = int.parse(match[1] ?? '0');
  final minutes = int.parse(match[2]!);
  final seconds = int.parse(match[3]!);
  if (seconds > 59 || (match[1] != null && minutes > 59)) return null;
  final duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
  return duration == Duration.zero ? null : duration;
}

/// [duration] as m:ss, or h:mm:ss from an hour.
String formatDurationText(Duration duration) {
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
