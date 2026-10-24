import 'package:flutter/services.dart';
import 'package:zema_core/zema_core.dart';

import 'library_scanner.dart';

/// [LibraryScanner] over Android MediaStore, through the Kotlin
/// `LibraryChannel` (`android/app/src/main/kotlin/.../LibraryChannel.kt`).
class MediaStoreLibraryScanner implements LibraryScanner {
  const MediaStoreLibraryScanner([
    this._channel = const MethodChannel(channelName),
  ]);

  static const channelName = 'com.zemaapp.zema/library';

  final MethodChannel _channel;

  @override
  bool get isSupported => true;

  @override
  Future<List<ScannedAudio>> scan() async {
    final rows = await _call<List<Object?>>('scan');
    return [
      for (final row in rows ?? const <Object?>[])
        if (row is Map<Object?, Object?>) audioFromRow(row),
    ];
  }

  @override
  Future<Uint8List?> loadArtwork(int mediaStoreId, {int size = 200}) =>
      _call<Uint8List>('loadArtwork', {'id': mediaStoreId, 'size': size});

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') {
        throw PermissionFailure('Audio access not granted', cause: e);
      }
      throw ScanFailure('MediaStore $method failed: ${e.code}', cause: e);
    } on MissingPluginException catch (e) {
      throw ScanFailure('Library channel is not registered', cause: e);
    }
  }
}

/// MediaStore's placeholder for a missing artist or album tag.
const _unknown = '<unknown>';

String? _tag(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == _unknown ? null : trimmed;
}

int? _int(Object? value) => value is num ? value.toInt() : null;

/// Maps one row from the Kotlin channel to a [ScannedAudio].
ScannedAudio audioFromRow(Map<Object?, Object?> row) => ScannedAudio(
  mediaStoreId: _int(row['id']) ?? 0,
  uri: row['uri'] as String? ?? '',
  path: row['path'] as String? ?? '',
  displayName: row['displayName'] as String? ?? '',
  title: _tag(row['title']),
  artist: _tag(row['artist']),
  album: _tag(row['album']),
  albumArtist: _tag(row['albumArtist']),
  trackNumber: _int(row['track']),
  year: _int(row['year']),
  duration: Duration(milliseconds: _int(row['durationMs']) ?? 0),
  sizeBytes: _int(row['sizeBytes']) ?? 0,
  dateAdded: DateTime.fromMillisecondsSinceEpoch(
    (_int(row['dateAddedSeconds']) ?? 0) * 1000,
    isUtc: true,
  ),
);
