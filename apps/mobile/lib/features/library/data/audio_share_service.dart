import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import 'media_store_library_scanner.dart';

final _log = Logger('library.share');

/// Hands a song's audio file to another app.
abstract interface class AudioShareService {
  /// False where songs can't be shared; the song menu then hides Share.
  bool get isSupported;

  /// Opens the system share sheet for [track]'s file. Returns false if it
  /// couldn't be opened.
  Future<bool> share(Track track);
}

/// Android: the share sheet with the MediaStore content URI, readable by
/// the receiving app. The file isn't copied.
class AndroidAudioShareService implements AudioShareService {
  const AndroidAudioShareService([
    this._channel = const MethodChannel(MediaStoreLibraryScanner.channelName),
  ]);

  final MethodChannel _channel;

  @override
  bool get isSupported => true;

  @override
  Future<bool> share(Track track) async {
    try {
      await _channel.invokeMethod<void>('share', {
        'uri': track.uri,
        'title': track.title,
      });
      return true;
    } on PlatformException catch (e) {
      _log.warning('Could not share a song: ${e.code}', e);
      return false;
    }
  }
}

class UnsupportedAudioShareService implements AudioShareService {
  const UnsupportedAudioShareService();

  @override
  bool get isSupported => false;

  @override
  Future<bool> share(Track track) async => false;
}
