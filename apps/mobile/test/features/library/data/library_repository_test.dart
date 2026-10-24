import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/library_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/library/data/library_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

/// A DAO whose writes fail, like a full disk.
class _FailingDao extends LibraryDao {
  _FailingDao(super.attachedDatabase);

  @override
  Future<void> applyReconciliation(TrackReconciliation changes) async =>
      throw StateError('disk full');
}

void main() {
  late ZemaDatabase db;
  late FakeLibraryScanner scanner;
  late LibraryRepository repository;

  setUp(() {
    db = ZemaDatabase(NativeDatabase.memory());
    scanner = FakeLibraryScanner();
    repository = LibraryRepository(scanner, db.libraryDao);
  });
  tearDown(() => db.close());

  Future<List<Track>> shown() =>
      repository.watchTracks(minDuration: const Duration(seconds: 30)).first;

  group('LibraryRepository', () {
    test('stores what the scanner finds and reports counts', () async {
      scanner.files = [
        scannedAudio(1, '/m/a.mp3', title: 'A'),
        scannedAudio(2, '/m/voice.mp3', durationMs: 10000),
      ];

      final result = await repository.sync();

      expect(result.scanned, 2);
      expect(result.added, 2);
      expect(result.updated, 0);
      expect(result.missing, 0);
      expect((await shown()).map((t) => t.title), ['A']);
    });

    test('reports updates and missing files on a rescan', () async {
      scanner.files = [
        scannedAudio(1, '/m/a.mp3', artist: 'Old'),
        scannedAudio(2, '/m/b.mp3', sizeBytes: 2),
      ];
      await repository.sync();

      scanner.files = [scannedAudio(1, '/m/a.mp3', artist: 'New')];
      final result = await repository.sync();

      expect(result.added, 0);
      expect(result.updated, 1);
      expect(result.missing, 1);
      expect((await shown()).single.artist, 'New');
    });

    test('a failed scan leaves the stored library as it was', () async {
      scanner.files = [scannedAudio(1, '/m/a.mp3')];
      await repository.sync();

      scanner.error = const ScanFailure('boom');

      await expectLater(repository.sync(), throwsA(isA<ScanFailure>()));
      expect(await shown(), hasLength(1));
    });

    test('passes a permission failure through', () async {
      scanner.error = const PermissionFailure('revoked');

      await expectLater(repository.sync(), throwsA(isA<PermissionFailure>()));
    });

    test('wraps database errors in DatabaseFailure', () async {
      scanner.files = [scannedAudio(1, '/m/a.mp3')];
      final broken = LibraryRepository(scanner, _FailingDao(db));

      await expectLater(broken.sync(), throwsA(isA<DatabaseFailure>()));
      expect(await shown(), isEmpty);
    });
  });
}
