import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('contribute.youtube');

/// What YouTube says about one video.
class YoutubeInfo {
  const YoutubeInfo({required this.title, this.author, this.thumbnail});

  final String title;

  /// The channel name.
  final String? author;
  final Uint8List? thumbnail;
}

/// Looks up a video's title and thumbnail. Tests use a fake.
abstract interface class YoutubeInfoService {
  /// [videoId]'s info, or null when it can't be had (offline, or no such
  /// video).
  Future<YoutubeInfo?> load(String videoId);
}

/// [YoutubeInfoService] from YouTube's oEmbed endpoint (no key needed),
/// kept in files under [directory] like avatars: `<id>.json` and
/// `<id>.jpg`.
class OEmbedYoutubeInfoService implements YoutubeInfoService {
  OEmbedYoutubeInfoService(
    this._directory, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Future<Directory> Function() _directory;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<YoutubeInfo?> load(String videoId) async {
    final directory = await _directory();
    final json = File(p.join(directory.path, '$videoId.json'));
    final jpg = File(p.join(directory.path, '$videoId.jpg'));
    try {
      if (await json.exists()) {
        return _parse(
          await json.readAsString(),
          await jpg.exists() ? await jpg.readAsBytes() : null,
        );
      }
      final url = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$videoId',
        'format': 'json',
      });
      final response = await _client.get(url).timeout(timeout);
      if (response.statusCode != 200) {
        _log.info('oEmbed: HTTP ${response.statusCode}');
        return null;
      }
      final body = utf8.decode(response.bodyBytes);
      Uint8List? thumbnail;
      final thumbnailUrl = (jsonDecode(body) as Map)['thumbnail_url'];
      if (thumbnailUrl is String) {
        final image = await _client
            .get(Uri.parse(thumbnailUrl))
            .timeout(timeout);
        if (image.statusCode == 200) thumbnail = image.bodyBytes;
      }
      await directory.create(recursive: true);
      await json.writeAsString(body, flush: true);
      if (thumbnail != null) await jpg.writeAsBytes(thumbnail, flush: true);
      return _parse(body, thumbnail);
    } on Object catch (e) {
      // Offline or unexpected: the user types the title instead.
      _log.info('oEmbed lookup failed', e);
      return null;
    }
  }

  static YoutubeInfo? _parse(String body, Uint8List? thumbnail) {
    final map = jsonDecode(body);
    if (map is! Map || map['title'] is! String) return null;
    return YoutubeInfo(
      title: map['title'] as String,
      author: map['author_name'] as String?,
      thumbnail: thumbnail,
    );
  }
}
