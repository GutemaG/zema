import 'contribution_rules.dart';

const _hosts = {
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
};

/// The video id in a YouTube link: watch, youtu.be, shorts, embed and live
/// links, on youtube.com, m., music. or youtube-nocookie.com, with or
/// without the scheme and extra parameters. A bare 11-character id is taken
/// as it is. Null when [link] isn't a link to one video.
String? youtubeVideoId(String link) {
  final text = link.trim();
  if (isValidVideoId(text)) return text;
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    id = segments.firstOrNull;
  } else if (_hosts.contains(host)) {
    id = switch (segments) {
      ['watch', ...] => uri.queryParameters['v'],
      ['shorts' || 'embed' || 'live' || 'v', final id, ...] => id,
      _ => null,
    };
  } else {
    id = null;
  }
  return id != null && isValidVideoId(id) ? id : null;
}
