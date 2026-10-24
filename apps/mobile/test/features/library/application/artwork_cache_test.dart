import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/artwork_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

/// Counts artwork loads; IDs in [withoutArt] have none, [failing] throws.
class _ArtScanner extends FakeLibraryScanner {
  final loads = <int>[];
  final withoutArt = <int>{};
  final failing = <int>{};

  @override
  Future<Uint8List?> loadArtwork(int mediaStoreId, {int size = 200}) async {
    loads.add(mediaStoreId);
    if (failing.contains(mediaStoreId)) {
      throw const ScanFailure('broken art');
    }
    if (withoutArt.contains(mediaStoreId)) return null;
    return Uint8List.fromList([mediaStoreId]);
  }
}

void main() {
  group('ArtworkCache', () {
    test('loads each image once', () async {
      final scanner = _ArtScanner();
      final cache = ArtworkCache(scanner);

      expect(await cache.load(1), [1]);
      expect(await cache.load(1), [1]);

      expect(scanner.loads, [1]);
    });

    test('shares a load that is still running', () async {
      final scanner = _ArtScanner();
      final cache = ArtworkCache(scanner);

      final results = await Future.wait([cache.load(2), cache.load(2)]);

      expect(results, [
        [2],
        [2],
      ]);
      expect(scanner.loads, [2]);
    });

    test('remembers files without art and failed loads', () async {
      final scanner = _ArtScanner()
        ..withoutArt.add(3)
        ..failing.add(4);
      final cache = ArtworkCache(scanner);

      expect(await cache.load(3), isNull);
      expect(await cache.load(4), isNull);
      expect(await cache.load(3), isNull);
      expect(await cache.load(4), isNull);

      expect(scanner.loads, [3, 4]);
    });

    test('drops the least recently used image past capacity', () async {
      final scanner = _ArtScanner();
      final cache = ArtworkCache(scanner, capacity: 2);

      await cache.load(1);
      await cache.load(2);
      await cache.load(1); // 1 is now the most recent.
      await cache.load(3); // Drops 2.
      await cache.load(1);
      await cache.load(2);

      expect(scanner.loads, [1, 2, 3, 2]);
    });
  });
}
