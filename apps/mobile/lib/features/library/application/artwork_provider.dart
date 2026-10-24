import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../data/library_scanner.dart';
import 'library_providers.dart';

final _log = Logger('library.artwork');

/// Album art by MediaStore ID; null when the file has none.
final artworkProvider = FutureProvider.autoDispose.family<Uint8List?, int>(
  (ref, mediaStoreId) => ref.watch(artworkCacheProvider).load(mediaStoreId),
);

final artworkCacheProvider = Provider<ArtworkCache>(
  (ref) => ArtworkCache(ref.watch(libraryScannerProvider)),
);

/// Keeps the most recently used [capacity] images in memory, so scrolling
/// back doesn't reload them. Files without art are remembered too.
class ArtworkCache {
  ArtworkCache(this._scanner, {this.capacity = 200});

  final LibraryScanner _scanner;
  final int capacity;
  // Map literals keep insertion order: the first key is the least recent.
  final _images = <int, Uint8List?>{};
  final _loading = <int, Future<Uint8List?>>{};

  Future<Uint8List?> load(int mediaStoreId) async {
    if (_images.containsKey(mediaStoreId)) {
      // Move to the most recent end.
      final image = _images.remove(mediaStoreId);
      return _images[mediaStoreId] = image;
    }
    return _loading[mediaStoreId] ??= _fetch(mediaStoreId);
  }

  Future<Uint8List?> _fetch(int mediaStoreId) async {
    Uint8List? image;
    try {
      image = await _scanner.loadArtwork(mediaStoreId);
    } catch (e) {
      _log.fine('No artwork for $mediaStoreId: $e');
    }
    _loading.removeWhere((id, _) => id == mediaStoreId);
    _images[mediaStoreId] = image;
    if (_images.length > capacity) _images.remove(_images.keys.first);
    return image;
  }
}
