/// A size for people, in powers of 1,000 as phones show storage: `512 B`,
/// `340 KB`, `1.2 MB`.
String formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes B';
  final kilobytes = (bytes / 1000).round();
  if (kilobytes < 1000) return '$kilobytes KB';
  return '${(bytes / (1000 * 1000)).toStringAsFixed(1)} MB';
}
