import 'dart:isolate';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/auto_backup.dart';
import 'package:zema/features/account/application/auto_backup_task.dart';
import 'package:zema/features/account/application/backup_service.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/data/backup_builder.dart';
import 'package:zema/features/account/data/backup_status.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 10, 30, 12);

  group('autoBackupDue', () {
    test('never backed up: due', () {
      expect(autoBackupDue(const BackupStatus(), now), isTrue);
    });

    test('at most once a day', () {
      BackupStatus at(Duration ago) =>
          BackupStatus(lastBackupAt: now.subtract(ago));
      expect(
        autoBackupDue(at(const Duration(hours: 23, minutes: 59)), now),
        isFalse,
      );
      expect(autoBackupDue(at(const Duration(hours: 24)), now), isTrue);
      expect(autoBackupDue(at(const Duration(days: 3)), now), isTrue);
    });

    test('never when Auto backup is off', () {
      expect(
        autoBackupDue(const BackupStatus(autoBackup: false), now),
        isFalse,
      );
    });
  });

  test('unmeteredConnection: Wi-Fi or Ethernet only', () {
    expect(unmeteredConnection([ConnectivityResult.wifi]), isTrue);
    expect(unmeteredConnection([ConnectivityResult.ethernet]), isTrue);
    expect(
      unmeteredConnection([ConnectivityResult.mobile, ConnectivityResult.wifi]),
      isTrue,
    );
    expect(unmeteredConnection([ConnectivityResult.mobile]), isFalse);
    expect(unmeteredConnection([ConnectivityResult.vpn]), isFalse);
    expect(unmeteredConnection([ConnectivityResult.none]), isFalse);
    expect(unmeteredConnection(const []), isFalse);
  });

  group('runAutoBackup', () {
    const user = 'user-1';
    late FakeBackupRepository backups;
    late BackupStatusStore store;
    late BackupService service;
    late ZemaDatabase db;
    var wifi = true;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backups = FakeBackupRepository();
      store = BackupStatusStore(await SharedPreferences.getInstance());
      db = memoryDatabase();
      wifi = true;
      service = BackupService(
        repository: backups,
        builder: backupBuilderOf(db),
        store: store,
        settings: () => const AppSettings(),
      );
    });

    Future<BackupOutcome?> run({String? userId = user, DateTime? at}) =>
        runAutoBackup(
          userId: userId,
          service: service,
          store: store,
          unmetered: () async => wifi,
          now: () => at ?? now,
        );

    Future<void> favorite(String title) async {
      final id = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              mediaStoreId: title.hashCode,
              uri: 'content://$title',
              path: '/m/$title.mp3',
              folder: '/m',
              title: title,
              durationMs: 1000,
              sizeBytes: 1,
              dateAdded: DateTime.utc(2026),
            ),
          );
      await db.collectionsDao.addFavorite(id);
    }

    test('due on Wi-Fi: backs up', () async {
      expect(await run(), BackupOutcome.done);
      expect(backups.saves, hasLength(1));
    });

    test('signed out: nothing', () async {
      expect(await run(userId: null), isNull);
      expect(backups.saves, isEmpty);
    });

    test('on mobile data: nothing', () async {
      wifi = false;
      expect(await run(), isNull);
      expect(backups.saves, isEmpty);
    });

    test('Auto backup off: nothing', () async {
      await store.write(user, const BackupStatus(autoBackup: false));
      expect(await run(), isNull);
      expect(backups.saves, isEmpty);
    });

    test('a day later only, and only when something changed', () async {
      await favorite('Tizita');
      expect(await run(), BackupOutcome.done);
      final first = backups.stored!.savedAt;

      // Too soon: not even checked.
      expect(await run(at: first.add(const Duration(hours: 2))), isNull);

      // A day later, unchanged: nothing uploaded.
      final dayLater = first.add(const Duration(days: 1));
      expect(await run(at: dayLater), BackupOutcome.unchanged);
      expect(backups.saves, hasLength(1));

      // Changed: uploaded.
      await favorite('Ambassel');
      expect(await run(at: dayLater), BackupOutcome.done);
      expect(backups.saves, hasLength(2));
    });

    test("another phone's backup is never replaced automatically", () async {
      backups.stored = StoredBackup(
        document: BackupDocument(createdAt: DateTime.utc(2026)),
        savedAt: DateTime.utc(2026),
      );
      expect(await run(), BackupOutcome.otherBackup);
      expect(backups.saves, isEmpty);
      expect((await store.read(user)).lastError, BackupError.otherBackup);
    });
  });

  group('runAutoBackupTask', () {
    test('asks the running app to back up, with its own session', () async {
      final port = ReceivePort();
      IsolateNameServer.removePortNameMapping(autoBackupPortName);
      IsolateNameServer.registerPortWithName(port.sendPort, autoBackupPortName);
      addTearDown(() {
        IsolateNameServer.removePortNameMapping(autoBackupPortName);
        port.close();
      });

      await runAutoBackupTask();

      await expectLater(port.first, completes);
    });
  });

  group('in the app', () {
    /// The app goes to the background and comes back.
    void leaveAndReturn(WidgetTester tester) {
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    late FakeBackupRepository backups;
    var wifi = true;

    setUp(() {
      backups = FakeBackupRepository();
      wifi = true;
    });

    Future<void> start(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
    }) => pumpZemaApp(
      tester,
      location: AppRoutes.home,
      auth: FakeAuthRepository(user: testUser),
      backups: backups,
      googlePicker: FakeGoogleAccountPicker(),
      onWifi: () => wifi,
      savedPrefs: {AccountChoiceController.key: true, ...prefs},
    );

    testWidgets('backs up when opened, signed in on Wi-Fi', (tester) async {
      await start(tester);
      expect(backups.saves, hasLength(1));
    });

    testWidgets('not on mobile data', (tester) async {
      wifi = false;
      await start(tester);
      expect(backups.saves, isEmpty);
    });

    testWidgets('not when Auto backup is off', (tester) async {
      await start(
        tester,
        prefs: {BackupStatusStore.key(testUser.id): '{"autoBackup": false}'},
      );
      expect(backups.saves, isEmpty);
    });

    testWidgets('not for a guest', (tester) async {
      await pumpZemaApp(
        tester,
        backups: backups,
        googlePicker: FakeGoogleAccountPicker(),
        onWifi: () => true,
        savedPrefs: {AccountChoiceController.key: true},
      );
      expect(backups.saves, isEmpty);
    });

    testWidgets('once a day: coming back later the same day does nothing', (
      tester,
    ) async {
      await start(tester);
      leaveAndReturn(tester);
      await tester.pumpAndSettle();
      expect(backups.saves, hasLength(1));
    });

    testWidgets('coming back to the app, now on Wi-Fi, backs up', (
      tester,
    ) async {
      wifi = false;
      await start(tester);
      expect(backups.saves, isEmpty, reason: 'mobile data at first');

      wifi = true;
      leaveAndReturn(tester);
      await tester.pumpAndSettle();
      expect(backups.saves, hasLength(1));
    });

    testWidgets("the background task's message backs up in the app", (
      tester,
    ) async {
      wifi = false;
      await start(tester);
      expect(backups.saves, isEmpty);

      wifi = true;
      await tester.runAsync(() async {
        await runAutoBackupTask();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(backups.saves, hasLength(1));
    });
  });
}
