import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('account.avatar');

/// The signed-in user's avatar image, kept on the phone so it shows
/// offline. Tests use a fake.
abstract interface class AvatarCache {
  /// [userId]'s avatar from [url]: the saved image, downloaded first when
  /// there is none or the URL changed. Offline, an older saved image; null
  /// when there is nothing to show.
  Future<Uint8List?> load(String userId, String url);

  /// Deletes every saved avatar, after a sign-out or a deleted account.
  Future<void> clear();
}

/// [AvatarCache] in files under [directory]: `<userId>` holds the image and
/// `<userId>.url` the URL it came from.
class FileAvatarCache implements AvatarCache {
  FileAvatarCache(
    this._directory, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Future<Directory> Function() _directory;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<Uint8List?> load(String userId, String url) async {
    final directory = await _directory();
    final image = File(p.join(directory.path, userId));
    final source = File('${image.path}.url');
    final saved = await _readOrNull(image);
    if (saved != null && await _readTextOrNull(source) == url) return saved;
    try {
      final response = await _client
          .get(Uri.parse(sized(url)))
          .timeout(timeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        _log.info('Avatar download: HTTP ${response.statusCode}');
        return saved;
      }
      await directory.create(recursive: true);
      await image.writeAsBytes(response.bodyBytes, flush: true);
      await source.writeAsString(url, flush: true);
      return response.bodyBytes;
    } on Object catch (e) {
      // Offline: keep showing the older image, if any.
      _log.info('Avatar download failed', e);
      return saved;
    }
  }

  @override
  Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  /// [url] asking for a [pixels]-wide image when it is a Google photo,
  /// which comes 96 pixels wide (`=s96-c`) by default: soft on Profile.
  static String sized(String url, {int pixels = 256}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.endsWith('googleusercontent.com')) return url;
    return url.replaceFirst(RegExp(r'=s\d+-c$'), '=s$pixels-c');
  }

  static Future<Uint8List?> _readOrNull(File file) async {
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  static Future<String?> _readTextOrNull(File file) async {
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }
}
