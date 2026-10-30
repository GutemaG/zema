import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/data/backup_status.dart';
import 'package:zema/features/account/presentation/backup_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late FakeAuthRepository auth;
  late FakeBackupRepository backups;
  late ZemaDatabase db;

  setUp(() {
    auth = FakeAuthRepository(user: testUser);
    backups = FakeBackupRepository();
    db = memoryDatabase();
  });

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.backup,
    Map<String, Object> prefs = const {},
  }) => pumpZemaApp(
    tester,
    location: location,
    auth: auth,
    backups: backups,
    database: db,
    googlePicker: FakeGoogleAccountPicker(),
    savedPrefs: {AccountChoiceController.key: true, ...prefs},
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<BackupStatus> savedStatus() async {
    final prefs = await savedPreferences();
    await prefs.reload();
    final json = prefs.getString(BackupStatusStore.key(testUser.id));
    return json == null
        ? const BackupStatus()
        : BackupStatusStore(prefs).readCached(testUser.id);
  }

  Future<void> favorite() async {
    final id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            mediaStoreId: 1,
            uri: 'content://1',
            path: '/storage/emulated/0/Music/Tizita.mp3',
            folder: '/storage/emulated/0/Music',
            title: 'Tizita',
            durationMs: 241000,
            sizeBytes: 1,
            dateAdded: DateTime.utc(2026),
          ),
        );
    await db.collectionsDao.addFavorite(id);
  }

  testWidgets('shows Never, Back up now, Auto backup (on) and the notes', (
    tester,
  ) async {
    await start(tester);

    expect(find.text(_l10n.backupSectionStatus.toUpperCase()), findsOneWidget);
    expect(find.text(_l10n.backupLast), findsOneWidget);
    expect(find.text(_l10n.backupNever), findsOneWidget);
    expect(find.text(_l10n.backupNow), findsOneWidget);
    expect(find.text(_l10n.backupAuto), findsOneWidget);
    expect(find.text(_l10n.backupAutoNote), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text(_l10n.backupIncludedTitle), findsOneWidget);
  });

  testWidgets('Back up now uploads, then shows the time and "Backed up"', (
    tester,
  ) async {
    await favorite();
    await start(tester);

    await tap(tester, find.text(_l10n.backupNow));

    expect(backups.saves.single.favorites.single.track.title, 'Tizita');
    expect(find.text(_l10n.backupDone), findsOneWidget);
    expect(find.text(_l10n.backupNever), findsNothing);
    final context = tester.element(find.byType(BackupScreen));
    expect(
      find.text(formatBackupTime(context, backups.stored!.savedAt)),
      findsOneWidget,
    );
    expect((await savedStatus()).lastBackupAt, backups.stored!.savedAt);
  });

  testWidgets('shows a spinner while backing up, and ignores more taps', (
    tester,
  ) async {
    backups.saveGate = Completer<void>();
    await start(tester);

    await tester.tap(find.text(_l10n.backupNow));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text(_l10n.backupNow));
    await tester.pump();

    backups.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(backups.saves, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('offline: a message and the error; the cloud is unchanged', (
    tester,
  ) async {
    await start(tester);
    backups.failure = const NetworkFailure('offline');

    await tap(tester, find.text(_l10n.backupNow));

    expect(find.text(_l10n.backupOffline), findsOneWidget);
    expect(find.text(_l10n.backupErrorOffline), findsOneWidget);
    expect(find.text(_l10n.backupNever), findsOneWidget);
    expect(backups.saves, isEmpty);
  });

  testWidgets('a server error: a message and the error', (tester) async {
    await start(tester);
    backups.failure = const BackendFailure('500');

    await tap(tester, find.text(_l10n.backupNow));

    expect(find.text(_l10n.backupFailed), findsOneWidget);
    expect(find.text(_l10n.backupErrorFailed), findsOneWidget);
  });

  group("another phone's backup", () {
    setUp(() {
      backups.stored = StoredBackup(
        document: BackupDocument(createdAt: DateTime.utc(2026, 5)),
        savedAt: DateTime.utc(2026, 5, 1, 9),
      );
    });

    testWidgets('asks first, naming its date; Cancel keeps it', (tester) async {
      await start(tester);

      await tap(tester, find.text(_l10n.backupNow));

      expect(find.text(_l10n.backupReplaceTitle), findsOneWidget);
      final context = tester.element(find.byType(BackupScreen));
      expect(
        find.text(
          _l10n.backupReplaceMessage(
            formatBackupTime(context, DateTime.utc(2026, 5, 1, 9)),
          ),
        ),
        findsOneWidget,
      );
      await tap(tester, find.text(_l10n.actionCancel));

      expect(backups.saves, isEmpty);
      expect(backups.stored!.savedAt, DateTime.utc(2026, 5, 1, 9));
      expect(find.text(_l10n.backupErrorOther), findsOneWidget);
    });

    testWidgets('Replace uploads this phone\'s library', (tester) async {
      await favorite();
      await start(tester);

      await tap(tester, find.text(_l10n.backupNow));
      await tap(tester, find.text(_l10n.backupReplace));

      expect(backups.saves.single.favorites, hasLength(1));
      expect(find.text(_l10n.backupDone), findsOneWidget);
      expect(find.text(_l10n.backupErrorOther), findsNothing);

      // Now it's this phone's backup: no more asking.
      await tap(tester, find.text(_l10n.backupNow));
      expect(find.text(_l10n.backupReplaceTitle), findsNothing);
      expect(backups.saves, hasLength(2));
    });
  });

  testWidgets('Auto backup can be turned off, and stays off', (tester) async {
    await start(tester);

    await tap(tester, find.byType(Switch));

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect((await savedStatus()).autoBackup, isFalse);
  });

  testWidgets('a guest sees only what is backed up', (tester) async {
    auth = FakeAuthRepository();
    await start(tester);

    expect(find.text(_l10n.backupNow), findsNothing);
    expect(find.text(_l10n.backupIncludedTitle), findsOneWidget);
  });

  testWidgets('Profile links to Backup & sync when signed in', (tester) async {
    await start(tester, location: AppRoutes.profile);

    await tap(tester, find.text(_l10n.backupTitle));

    expect(find.byType(BackupScreen), findsOneWidget);
  });

  testWidgets('a guest\'s Profile has no Backup & sync link', (tester) async {
    auth = FakeAuthRepository();
    await start(tester, location: AppRoutes.profile);

    expect(find.text(_l10n.backupTitle), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text with an error ($brightness)', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      await pumpZemaApp(
        tester,
        location: AppRoutes.backup,
        phoneBrightness: brightness,
        auth: auth,
        backups: backups,
        database: db,
        googlePicker: FakeGoogleAccountPicker(),
        savedPrefs: {
          AccountChoiceController.key: true,
          'themeMode': brightness.name,
        },
      );
      backups.stored = StoredBackup(
        document: BackupDocument(createdAt: DateTime.utc(2026)),
        savedAt: DateTime.utc(2026),
      );
      await tap(tester, find.text(_l10n.backupNow));
      await tap(tester, find.text(_l10n.actionCancel));

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.backupErrorOther), findsOneWidget);
    });
  }
}
