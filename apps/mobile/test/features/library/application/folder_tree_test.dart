import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/folder_tree.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

const _phone = '/storage/emulated/0';

var _nextId = 1;
Track _track(String path, {String? title}) {
  final id = _nextId++;
  return Track.fromScan(id, scannedAudio(id, path, title: title));
}

void main() {
  group('locateFolder', () {
    test('internal storage is the phone', () {
      final location = locateFolder('$_phone/Telegram/Telegram Audio');

      expect(location.root, _phone);
      expect(location.kind, StorageKind.phone);
      expect(location.segments, ['Telegram', 'Telegram Audio']);
      expect(location.breadcrumb, [
        _phone,
        '$_phone/Telegram',
        '$_phone/Telegram/Telegram Audio',
      ]);
    });

    test('a second user profile is the phone too', () {
      expect(
        locateFolder('/storage/emulated/10/Music').root,
        '/storage/emulated/10',
      );
    });

    test('another storage volume is an SD card', () {
      final location = locateFolder('/storage/1A2B-3C4D/Music');

      expect(location.root, '/storage/1A2B-3C4D');
      expect(location.kind, StorageKind.sdCard);
      expect(location.segments, ['Music']);
    });

    test('the root itself has no segments', () {
      final location = locateFolder(_phone);

      expect(location.segments, isEmpty);
      expect(location.breadcrumb, [_phone]);
    });

    test('paths outside /storage are rooted at /', () {
      final location = locateFolder('/m/sub');

      expect(location.root, '/');
      expect(location.kind, StorageKind.phone);
      expect(location.breadcrumb, ['/', '/m', '/m/sub']);
    });
  });

  group('FolderIndex', () {
    final tracks = [
      _track('$_phone/Music/b.mp3', title: 'Beta'),
      _track('$_phone/Music/a.mp3', title: 'alpha'),
      _track('$_phone/Music/Zema/c.mp3'),
      _track('$_phone/Telegram/Telegram Audio/d.mp3'),
      _track('$_phone/Telegram/Telegram Audio/e.mp3'),
      _track('$_phone/Download/መዝሙር/f.mp3'),
    ];
    final index = FolderIndex.from(tracks);

    test('lists folders that hold songs directly, by name', () {
      expect(index.folders, [
        const FolderEntry(path: '$_phone/Music', name: 'Music', songCount: 2),
        const FolderEntry(
          path: '$_phone/Telegram/Telegram Audio',
          name: 'Telegram Audio',
          songCount: 2,
        ),
        const FolderEntry(
          path: '$_phone/Music/Zema',
          name: 'Zema',
          songCount: 1,
        ),
        const FolderEntry(
          path: '$_phone/Download/መዝሙር',
          name: 'መዝሙር',
          songCount: 1,
        ),
      ]);
    });

    test('folder contents: subfolders with all songs below, then songs', () {
      final music = index.contentsOf('$_phone/Music');

      expect(music.subfolders, [
        const FolderEntry(
          path: '$_phone/Music/Zema',
          name: 'Zema',
          songCount: 1,
        ),
      ]);
      expect([for (final t in music.tracks) t.title], ['alpha', 'Beta']);
      expect(music.totalCount, 3);
    });

    test('a folder with only subfolders counts every song below it', () {
      final root = index.contentsOf(_phone);

      expect(root.tracks, isEmpty);
      expect(root.subfolders, [
        const FolderEntry(
          path: '$_phone/Download',
          name: 'Download',
          songCount: 1,
        ),
        const FolderEntry(path: '$_phone/Music', name: 'Music', songCount: 3),
        const FolderEntry(
          path: '$_phone/Telegram',
          name: 'Telegram',
          songCount: 2,
        ),
      ]);
      expect(root.totalCount, 6);
    });

    test('all songs under a folder: its own first, then subfolders', () {
      expect(
        [for (final t in index.tracksUnder('$_phone/Music')) t.title],
        ['alpha', 'Beta', 'c'],
      );
      expect(index.tracksUnder(_phone), hasLength(6));
    });

    test('a folder with nothing visible is empty', () {
      expect(index.contentsOf('$_phone/Gone').isEmpty, isTrue);
      expect(
        index.contentsOf('$_phone/Mus').isEmpty,
        isTrue,
        reason: 'a name prefix is not a parent',
      );
    });

    test('an empty library has no folders', () {
      expect(FolderIndex.from(const []).folders, isEmpty);
    });
  });
}
