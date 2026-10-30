import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/account/application/backup_service.dart';
import 'package:zema/features/account/data/backup_builder.dart';
import 'package:zema/features/account/data/backup_status.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';

void main() {
  const user = 'user-1';
  late ZemaDatabase db;
  late FakeBackupRepository backups;
  late BackupStatusStore store;
  late BackupService service;
  var settings = const AppSettings();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = memoryDatabase();
    backups = FakeBackupRepository();
    store = BackupStatusStore(await SharedPreferences.getInstance());
    settings = const AppSettings();
    service = BackupService(
      repository: backups,
      builder: backupBuilderOf(db),
      store: store,
      settings: () => settings,
    );
  });

  Future<int> addFavorite(String name) async {
    final id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            mediaStoreId: name.hashCode,
            uri: 'content://$name',
            path: '/storage/emulated/0/Music/$name.mp3',
            folder: '/storage/emulated/0/Music',
            title: name,
            durationMs: 200000,
            sizeBytes: 1,
            dateAdded: DateTime.utc(2026),
          ),
        );
    await db.collectionsDao.addFavorite(id);
    return id;
  }

  test('uploads the library and records the time on this phone', () async {
    await addFavorite('Tizita');

    final result = await service.backUp(user);

    expect(result.outcome, BackupOutcome.done);
    expect(backups.saves.single.favorites.single.track.title, 'Tizita');
    final status = await store.read(user);
    expect(status.lastBackupAt, backups.stored!.savedAt);
    expect(status.syncedAt, backups.stored!.savedAt);
    expect(status.lastError, isNull);
    expect(status.contentHash, isNotNull);
  });

  test('the settings go in as they are when the backup runs', () async {
    settings = const AppSettings(gapless: false);
    await service.backUp(user);
    expect(backups.saves.single.settings['gapless'], false);
  });

  test(
    'a second backup from this phone replaces the first without asking',
    () async {
      await service.backUp(user);
      await addFavorite('Ambassel');

      final result = await service.backUp(user);

      expect(result.outcome, BackupOutcome.done);
      expect(backups.saves, hasLength(2));
      expect(backups.stored!.document.favorites, hasLength(1));
    },
  );

  test("another phone's backup is not replaced without say-so", () async {
    backups.stored = StoredBackup(
      document: BackupDocument(createdAt: DateTime.utc(2026)),
      savedAt: DateTime.utc(2026, 5),
    );
    await addFavorite('Tizita');

    final result = await service.backUp(user);

    expect(result.outcome, BackupOutcome.otherBackup);
    expect(result.otherSavedAt, DateTime.utc(2026, 5));
    expect(backups.saves, isEmpty);
    expect((await store.read(user)).lastError, BackupError.otherBackup);

    final replaced = await service.backUp(user, replace: true);
    expect(replaced.outcome, BackupOutcome.done);
    expect(backups.saves, hasLength(1));
    final status = await store.read(user);
    expect(status.lastError, isNull);
    expect(status.syncedAt, backups.stored!.savedAt);

    // Now it is this phone's: no more asking.
    expect((await service.backUp(user)).outcome, BackupOutcome.done);
  });

  test('offline: the cloud is unchanged and the error is kept', () async {
    await service.backUp(user);
    final before = await store.read(user);
    backups.failure = const NetworkFailure('offline');

    final result = await service.backUp(user);

    expect(result.outcome, BackupOutcome.offline);
    expect(backups.saves, hasLength(1));
    final status = await store.read(user);
    expect(status.lastError, BackupError.offline);
    expect(status.lastBackupAt, before.lastBackupAt);
  });

  test('a server error: failed, and the next success clears it', () async {
    backups.failure = const BackendFailure('500');
    expect((await service.backUp(user)).outcome, BackupOutcome.failed);
    expect((await store.read(user)).lastError, BackupError.failed);

    expect((await service.backUp(user)).outcome, BackupOutcome.done);
    expect((await store.read(user)).lastError, isNull);
  });

  test('skipUnchanged uploads nothing when the library is unchanged', () async {
    await addFavorite('Tizita');
    await service.backUp(user);

    final again = await service.backUp(user, skipUnchanged: true);
    expect(again.outcome, BackupOutcome.unchanged);
    expect(backups.saves, hasLength(1));

    await addFavorite('Ambassel');
    final changed = await service.backUp(user, skipUnchanged: true);
    expect(changed.outcome, BackupOutcome.done);
    expect(backups.saves, hasLength(2));
  });

  test(
    'without skipUnchanged, an unchanged library is uploaded anyway',
    () async {
      await service.backUp(user);
      expect((await service.backUp(user)).outcome, BackupOutcome.done);
      expect(backups.saves, hasLength(2));
    },
  );

  test('backupContentHash ignores only the time made', () {
    final a = BackupDocument(createdAt: DateTime.utc(2026));
    final b = BackupDocument(createdAt: DateTime.utc(2027));
    final c = BackupDocument(
      createdAt: DateTime.utc(2026),
      settings: const {'gapless': true},
    );
    expect(backupContentHash(a), backupContentHash(b));
    expect(backupContentHash(a), isNot(backupContentHash(c)));
  });

  group('BackupStatusStore', () {
    test('defaults: never backed up, auto backup on', () async {
      final status = await store.read('nobody');
      expect(status.lastBackupAt, isNull);
      expect(status.autoBackup, isTrue);
      expect(status.lastError, isNull);
    });

    test('round-trips, per user', () async {
      final status = BackupStatus(
        lastBackupAt: DateTime.utc(2026, 10, 30, 1, 2, 3, 4, 5),
        lastError: BackupError.offline,
        autoBackup: false,
        syncedAt: DateTime.utc(2026, 10, 30, 1, 2, 3, 4, 5),
        contentHash: 42,
      );
      await store.write('a', status);
      expect(await store.read('a'), status);
      expect(await store.read('b'), const BackupStatus());

      await store.remove('a');
      expect(await store.read('a'), const BackupStatus());
    });

    test('an unreadable status reads as the defaults', () async {
      SharedPreferences.setMockInitialValues({BackupStatusStore.key('a'): '{'});
      final broken = BackupStatusStore(await SharedPreferences.getInstance());
      expect(await broken.read('a'), const BackupStatus());
    });
  });
}
