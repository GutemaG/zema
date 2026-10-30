import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/data/backup_status.dart';
import 'package:zema/features/account/presentation/backup_screen.dart';
import 'package:zema/features/account/presentation/restore_screen.dart';
import 'package:zema/features/account/presentation/sign_in_screen.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_sync_controller.dart';
import 'package:zema/features/settings/presentation/settings_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

TrackIdentity id(String file, {String? artist, int ms = 60000}) =>
    TrackIdentity(
      title: file.substring(0, file.lastIndexOf('.')),
      artist: artist,
      durationMs: ms,
      fileName: file,
    );

final savedAt = DateTime.utc(2026, 10, 29, 9);

/// S26's Restore button ("Restore" is the title too).
final restoreButton = find.byIcon(Icons.restore);

void main() {
  late FakeAuthRepository auth;
  late FakeBackupRepository backups;
  late ZemaDatabase db;
  late FakeLibraryScanner scanner;

  // The new phone's music: the backed-up songs, copied to another folder.
  final phoneFiles = [
    scannedAudio(
      1,
      '/storage/emulated/0/Download/Tizita.mp3',
      durationMs: 241000,
    ),
    scannedAudio(
      2,
      '/storage/emulated/0/Download/Amlak.mp3',
      durationMs: 75000,
    ),
  ];

  final backup = BackupDocument(
    createdAt: savedAt,
    favorites: [
      BackupFavorite(track: id('Tizita.mp3', ms: 241000), addedAt: savedAt),
      BackupFavorite(
        track: id('Gone.mp3', artist: 'Aster'),
        addedAt: savedAt,
      ),
    ],
    playlists: [
      BackupPlaylist(
        name: 'Morning',
        tracks: [id('Amlak.mp3', ms: 75000), id('Tizita.mp3', ms: 241000)],
      ),
    ],
    lyricsChoices: [BackupLyricsChoice(track: id('Amlak.mp3', ms: 75000))],
    settings: const {'gapless': false},
  );

  setUp(() {
    auth = FakeAuthRepository(user: testUser);
    backups = FakeBackupRepository(
      stored: StoredBackup(document: backup, savedAt: savedAt),
    );
    db = memoryDatabase();
    scanner = FakeLibraryScanner(phoneFiles);
  });

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.restore,
    Map<String, Object> prefs = const {},
  }) => pumpZemaApp(
    tester,
    location: location,
    auth: auth,
    backups: backups,
    database: db,
    libraryScanner: scanner,
    googlePicker: FakeGoogleAccountPicker(),
    savedPrefs: {
      AccountChoiceController.key: true,
      LibraryAccessController.explainedKey: true,
      ...prefs,
    },
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String found(WidgetTester tester) {
    final context = tester.element(find.byType(RestoreScreen));
    return _l10n.restoreFound(
      formatBackupTime(context, savedAt),
      _l10n.restoreCountFavorites(2),
      _l10n.restoreCountPlaylists(1),
    );
  }

  Future<BackupStatus> status() async {
    final prefs = await savedPreferences();
    return BackupStatusStore(prefs).read(testUser.id);
  }

  testWidgets('shows the backup: date, favorites, playlists, settings', (
    tester,
  ) async {
    await start(tester);

    expect(find.text(found(tester)), findsOneWidget);
    expect(restoreButton, findsOneWidget);
    expect(find.text(_l10n.restoreStartFresh), findsOneWidget);
  });

  testWidgets('Restore merges, then lists what was added and not found', (
    tester,
  ) async {
    await start(tester);

    await tap(tester, restoreButton);

    expect(find.text(_l10n.restoreDoneTitle), findsOneWidget);
    expect(find.text(_l10n.restoreDoneFavorites(1)), findsOneWidget);
    expect(find.text(_l10n.restoreDonePlaylists(2)), findsOneWidget);
    expect(find.text(_l10n.restoreDoneChoices(1)), findsOneWidget);
    expect(find.text(_l10n.restoreNotFoundTitle(1)), findsOneWidget);
    expect(find.text('Gone'), findsOneWidget);
    expect(find.text('Aster'), findsOneWidget);

    expect(await db.select(db.favorites).get(), hasLength(1));
    final playlist = await db.select(db.playlists).getSingle();
    expect(playlist.name, 'Morning');
    expect(await db.select(db.playlistEntries).get(), hasLength(2));
    expect(await db.unmatchedDao.all(), hasLength(1));
    final prefs = await savedPreferences();
    expect(prefs.getBool('gapless'), isFalse, reason: 'settings restored');
    expect(
      (await status()).syncedAt,
      savedAt,
      reason: 'the next backup from here replaces it without asking',
    );

    await tap(tester, find.text(_l10n.restoreDone));
    expect(find.byType(RestoreScreen), findsNothing);
  });

  testWidgets('Start fresh changes nothing and keeps the cloud backup', (
    tester,
  ) async {
    await start(tester);

    await tap(tester, find.text(_l10n.restoreStartFresh));

    expect(find.byType(RestoreScreen), findsNothing);
    expect(await db.select(db.favorites).get(), isEmpty);
    expect(await db.select(db.playlists).get(), isEmpty);
    expect(backups.stored, isNotNull);
    expect(backups.saves, isEmpty);
    expect((await status()).syncedAt, isNull);
  });

  testWidgets('waits for the first library scan, then matches', (tester) async {
    final gated = GatedLibraryScanner(phoneFiles)..hold = true;
    scanner = gated;
    await start(tester);

    await tester.tap(restoreButton);
    await tester.pump();
    await tester.pump();
    expect(find.text(_l10n.restoreWaitingForScan), findsOneWidget);

    gated.release();
    await tester.pumpAndSettle();
    expect(find.text(_l10n.restoreDoneFavorites(1)), findsOneWidget);
  });

  testWidgets('no backup: says so', (tester) async {
    backups.stored = null;
    await start(tester);
    expect(find.text(_l10n.restoreNone), findsOneWidget);
  });

  testWidgets('offline: says so, and Try again loads it', (tester) async {
    backups.failure = const NetworkFailure('offline');
    await start(tester);
    expect(find.text(_l10n.restoreOffline), findsOneWidget);

    await tap(tester, find.text(_l10n.restoreRetry));
    expect(find.text(found(tester)), findsOneWidget);
  });

  testWidgets('a backup from a newer app asks to update', (tester) async {
    backups.failure = const BackupFormatFailure('v2', newerFormat: true);
    await start(tester);
    expect(find.text(_l10n.restoreNewer), findsOneWidget);
    expect(find.text(_l10n.restoreRetry), findsNothing);
  });

  group('after sign-in', () {
    Future<void> signInFromSettings(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
    }) async {
      auth = FakeAuthRepository();
      await start(tester, location: AppRoutes.settings, prefs: prefs);
      await tap(tester, find.text(_l10n.settingsAccountBackup));
      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));
      await tap(tester, find.text(_l10n.signInWithGoogle));
    }

    testWidgets('a backup this phone hasn\'t seen opens S26 in S24\'s place', (
      tester,
    ) async {
      await signInFromSettings(tester);

      expect(find.byType(RestoreScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);

      await tap(tester, find.text(_l10n.restoreStartFresh));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('this phone\'s own backup is not offered again', (
      tester,
    ) async {
      // This phone saved (or restored) exactly that cloud backup before.
      await signInFromSettings(
        tester,
        prefs: {
          BackupStatusStore.key(testUser.id):
              '{"syncedAt": "${savedAt.toIso8601String()}"}',
        },
      );

      expect(find.byType(RestoreScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('no backup: back where the user was', (tester) async {
      backups.stored = null;
      await signInFromSettings(tester);

      expect(find.byType(RestoreScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('offline: back where the user was', (tester) async {
      backups.failure = const NetworkFailure('offline');
      await signInFromSettings(tester);

      expect(find.byType(RestoreScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  testWidgets('S25b\'s Restore opens S26', (tester) async {
    await start(tester, location: AppRoutes.backup);

    await tap(tester, find.text(_l10n.backupRestore));

    expect(find.byType(RestoreScreen), findsOneWidget);
  });

  testWidgets('songs not found are added once a rescan finds them', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, restoreButton);
    expect(await db.unmatchedDao.all(), hasLength(1));

    scanner.files = [
      ...phoneFiles,
      scannedAudio(3, '/storage/emulated/0/Music/Gone.mp3', artist: 'Aster'),
    ];
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await container.read(librarySyncProvider.notifier).sync();
    await tester.pumpAndSettle();

    expect(await db.unmatchedDao.all(), isEmpty);
    expect(await db.select(db.favorites).get(), hasLength(2));
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      await pumpZemaApp(
        tester,
        location: AppRoutes.restore,
        phoneBrightness: brightness,
        auth: auth,
        backups: backups,
        database: db,
        libraryScanner: scanner,
        googlePicker: FakeGoogleAccountPicker(),
        savedPrefs: {
          AccountChoiceController.key: true,
          LibraryAccessController.explainedKey: true,
          'themeMode': brightness.name,
        },
      );
      expect(tester.takeException(), isNull);
      // Content and buttons scroll together at this size.
      await tester.ensureVisible(restoreButton);
      await tester.pumpAndSettle();
      await tap(tester, restoreButton);
      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.restoreDone).hitTestable(), findsOneWidget);
    });
  }
}
