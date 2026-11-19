import '../library/track.dart';

final _brackets = RegExp(r'\[[^\]]*\]');
final _bitrate = RegExp(r'\(\s*\d+\s*(kbps)?\s*\)', caseSensitive: false);
final _channel = RegExp(r'@[\p{L}\p{N}_.]+', unicode: true);
final _youTubeId = RegExp(r'\s+-\s+([A-Za-z0-9_-]{11})\s*$');
final _trackNumber = RegExp(r'\b(track|cd)\s*\d+\b', caseSensitive: false);
final _leadingNumber = RegExp(r'^\d{1,3}(\s*[-._)]\s*|\s+)');
final _edges = RegExp(r'^[\s\-–.,:|]+|[\s\-–.,:|]+$');
final _spaces = RegExp(r'\s+');
final _placeholder = RegExp(
  r'^(new (title|artist|album)|unknown( artist| album)?|untitled|<unknown>|'
  r'various artists|no title|track)$',
  caseSensitive: false,
);
final _letter = RegExp(r'\p{L}', unicode: true);

/// [tag] without what music sites and rippers add around a title or artist:
/// `[...]`, `(128)`, `@channel`, a YouTube ID after ` - `, `Track N`, `CD N`,
/// and `_` for spaces.
String cleanTag(String tag) {
  var s = tag;
  final id = _youTubeId.firstMatch(s);
  if (id != null && _looksLikeId(id.group(1)!)) s = s.substring(0, id.start);
  s = s
      .replaceAll(_channel, ' ')
      .replaceAll('_', ' ')
      .replaceAll(_brackets, ' ')
      .replaceAll(_bitrate, ' ')
      .replaceAll(_trackNumber, ' ')
      .replaceAll(_spaces, ' ');
  return s.replaceAll(_edges, '');
}

/// A file name (without its extension) as a title: [cleanTag] and no
/// leading track number (`01 `, `01_`, `04 - `).
String cleanFileName(String name) =>
    cleanTag(name.trim().replaceFirst(_leadingNumber, ''));

/// Whether [tag] says nothing: missing, empty once cleaned, without a
/// letter, or a placeholder such as `New Artist (35)` or `Unknown`.
bool isJunkTag(String? tag) {
  if (tag == null) return true;
  final s = cleanTag(tag);
  return !_letter.hasMatch(s) || _placeholder.hasMatch(s);
}

/// The title to match [track] by: its cleaned title tag, or its cleaned file
/// name when the tag is junk or was the file name already.
String matchTitle(Track track) {
  final stem = _stem(track.path);
  if (isJunkTag(track.title) || track.title == stem) {
    final name = cleanFileName(stem);
    return isJunkTag(name) ? '' : name;
  }
  return cleanTag(track.title);
}

/// The artist to match [track] by, or null when the tag is junk, a channel
/// name (`@…`) or just the title again.
String? matchArtist(Track track) {
  final artist = track.artist?.trim();
  if (artist == null || artist.startsWith('@') || isJunkTag(artist)) {
    return null;
  }
  final clean = cleanTag(artist);
  return clean.toLowerCase() == cleanTag(track.title).toLowerCase()
      ? null
      : clean;
}

/// Where [track]'s artist may be written when its tag isn't: its
/// [matchTitle] and its cleaned file name.
String artistHints(Track track) =>
    '${matchTitle(track)} ${cleanFileName(_stem(track.path))}';

/// Whether [s] looks like a video ID rather than a word: it has a digit, or
/// a capital after its first letter.
bool _looksLikeId(String s) =>
    RegExp(r'\d').hasMatch(s) || RegExp(r'[A-Z]').hasMatch(s.substring(1));

String _stem(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
