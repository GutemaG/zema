/// `m:ss`, or `h:mm:ss` from an hour.
String formatDuration(Duration d) {
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final m = d.inMinutes % 60;
  if (d.inHours == 0) return '$m:$s';
  return '${d.inHours}:${m.toString().padLeft(2, '0')}:$s';
}

/// `m:ss.t`, for line times.
String formatTime(Duration d) =>
    '${formatDuration(d)}.${(d.inMilliseconds % 1000) ~/ 100}';

/// How long ago [time] was, roughly: "5 min", "3 h", "2 d".
String formatAge(DateTime time, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(time);
  if (age.inMinutes < 1) return 'now';
  if (age.inHours < 1) return '${age.inMinutes} min';
  if (age.inDays < 1) return '${age.inHours} h';
  return '${age.inDays} d';
}
