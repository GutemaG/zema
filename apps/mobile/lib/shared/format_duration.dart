/// `m:ss`, or `h:mm:ss` from one hour, e.g. `3:07`, `1:02:45`.
String formatDuration(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';
  final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}
