import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/account/application/account_providers.dart';
import 'package:zema/features/account/application/backup.dart';
import 'package:zema/features/account/application/backup_service.dart';
import 'package:zema/features/account/application/profile.dart';
import 'package:zema/features/account/data/backup_status.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeBackupRepository backups;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository(user: testUser);
    backups = FakeBackupRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        databaseProvider.overrideWithValue(memoryDatabase()),
        ...accountOverrides(auth: auth, backups: backups),
      ],
    );
    addTearDown(container.dispose);
    container.listen(backupProvider, (_, _) {});
    await container.read(authUserProvider.future);
  });

  test('a second Back up now while one runs is ignored', () async {
    backups.saveGate = Completer<void>();
    final controller = container.read(backupProvider.notifier);

    final first = controller.backUpNow();
    await pumpEventQueue();
    expect(container.read(backupProvider).running, isTrue);
    expect(await controller.backUpNow(), isNull);

    backups.saveGate!.complete();
    expect((await first)?.outcome, BackupOutcome.done);
    expect(backups.saves, hasLength(1));
    expect(container.read(backupProvider).running, isFalse);
    expect(container.read(backupProvider).status?.lastBackupAt, isNotNull);
  });

  test('a guest has no status and cannot back up', () async {
    await auth.signOut();
    await pumpEventQueue();
    expect(container.read(backupProvider).status, isNull);
    expect(await container.read(backupProvider.notifier).backUpNow(), isNull);
    expect(backups.saves, isEmpty);
  });

  test('delete account forgets the backup status; sign-out keeps it', () async {
    final store = container.read(backupStatusStoreProvider);
    await container.read(backupProvider.notifier).backUpNow();
    expect((await store.read(testUser.id)).syncedAt, isNotNull);

    final actions = container.read(accountActionsProvider.notifier);
    container.listen(accountActionsProvider, (_, _) {});
    await actions.signOut();
    expect((await store.read(testUser.id)).syncedAt, isNotNull);

    await auth.signInWithGoogle(idToken: 'token');
    await actions.deleteAccount();
    expect(await store.read(testUser.id), const BackupStatus());
  });
}
