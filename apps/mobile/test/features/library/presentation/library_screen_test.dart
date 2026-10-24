import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_sync_controller.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/presentation/library_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

const _explained = {LibraryAccessController.explainedKey: true};

List<ScannedAudio> _testFiles() => [
  scannedAudio(
    1,
    '/m/Zema/01 Kidus.mp3',
    title: 'Kidus Kidus',
    artist: 'Zerfe',
  ),
  scannedAudio(
    2,
    '/m/መዝሙር/ቅዱስ.mp3',
    title: 'ቅዱስ ቅዱስ ቅዱስ',
    artist: 'ሊቀ መዘምራን ይልማ ኃይሉ',
  ),
  scannedAudio(3, '/m/Download/untagged_mezmur.mp3'),
  scannedAudio(4, '/m/Recordings/Voice 001.mp3', durationMs: 10000),
];

Future<void> _pumpLibrary(
  WidgetTester tester, {
  FakeLibraryScanner? scanner,
  FakeAudioPermissionService? permissions,
  Map<String, Object> savedPrefs = _explained,
  Brightness phoneBrightness = Brightness.dark,
  bool settle = true,
}) => pumpZemaApp(
  tester,
  location: AppRoutes.library,
  libraryScanner: scanner ?? FakeLibraryScanner(_testFiles()),
  permissions: permissions,
  savedPrefs: savedPrefs,
  phoneBrightness: phoneBrightness,
  settle: settle,
);

EmptyState _emptyState(WidgetTester tester) =>
    tester.widget<EmptyState>(find.byType(EmptyState));

/// Fails status checks until [fail] is turned off.
class _ThrowingPermissions extends FakeAudioPermissionService {
  bool fail = true;

  @override
  Future<AudioAccess> status() async {
    if (fail) throw StateError('permission plugin crashed');
    return super.status();
  }
}

/// A scanner whose first scan waits until [finish] is called.
class _HeldScanner extends FakeLibraryScanner {
  _HeldScanner(super.files);

  final _gate = Completer<void>();

  void finish() => _gate.complete();

  @override
  Future<List<ScannedAudio>> scan() async {
    await _gate.future;
    return super.scan();
  }
}

void main() {
  group('Library access', () {
    testWidgets('explains before asking, the first time', (tester) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
      );
      await _pumpLibrary(tester, permissions: permissions, savedPrefs: {});

      expect(find.text(_l10n.libraryAccessTitle), findsOneWidget);
      expect(find.text(_l10n.libraryAccessMessage), findsOneWidget);
      expect(find.text(_l10n.libraryAccessAllow), findsOneWidget);
      expect(find.text(_l10n.libraryAccessNotNow), findsOneWidget);
      expect(permissions.requests, 0);
    });

    testWidgets('Allow asks the system, then scans and lists the music', (
      tester,
    ) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
      );
      await _pumpLibrary(tester, permissions: permissions, savedPrefs: {});

      await tester.tap(find.text(_l10n.libraryAccessAllow));
      await tester.pumpAndSettle();

      expect(permissions.requests, 1);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
      expect(find.text('Kidus Kidus'), findsOneWidget);
    });

    testWidgets('Not now shows Grant access, which asks the system', (
      tester,
    ) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
        onRequest: AudioAccess.denied,
      );
      await _pumpLibrary(tester, permissions: permissions, savedPrefs: {});

      await tester.tap(find.text(_l10n.libraryAccessNotNow));
      await tester.pumpAndSettle();
      expect(permissions.requests, 0);
      expect(_emptyState(tester).title, _l10n.libraryAccessDeniedTitle);

      await tester.tap(find.text(_l10n.libraryAccessGrant));
      await tester.pumpAndSettle();
      expect(permissions.requests, 1);
      expect(find.text(_l10n.libraryAccessGrant), findsOneWidget);
    });

    testWidgets('a permanent denial offers the system settings', (
      tester,
    ) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
        onRequest: AudioAccess.permanentlyDenied,
      );
      await _pumpLibrary(tester, permissions: permissions);

      await tester.tap(find.text(_l10n.libraryAccessGrant));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.libraryAccessSettingsMessage), findsOneWidget);

      await tester.tap(find.text(_l10n.libraryAccessOpenSettings));
      await tester.pumpAndSettle();
      expect(permissions.settingsOpened, 1);
    });

    testWidgets('returning from the settings with access starts the scan', (
      tester,
    ) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.permanentlyDenied,
      );
      final scanner = FakeLibraryScanner(_testFiles());
      await _pumpLibrary(tester, permissions: permissions, scanner: scanner);
      expect(scanner.scans, 0);

      permissions.current = AudioAccess.granted;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();

      expect(scanner.scans, 1);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
    });

    testWidgets('a failing permission check offers Try again', (tester) async {
      final permissions = _ThrowingPermissions();
      await _pumpLibrary(tester, permissions: permissions);

      expect(_emptyState(tester).kind, EmptyStateKind.error);

      permissions.fail = false;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
    });

    testWidgets('iOS says the library is not available yet', (tester) async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.unsupported,
      );
      final scanner = FakeLibraryScanner(_testFiles());
      await _pumpLibrary(tester, permissions: permissions, scanner: scanner);

      expect(_emptyState(tester).title, _l10n.libraryUnsupportedTitle);
      expect(find.byType(FilledButton), findsNothing);
      expect(permissions.requests, 0);
      expect(scanner.scans, 0);
    });
  });

  group('Library tracks', () {
    testWidgets('lists visible tracks with count and artist', (tester) async {
      await _pumpLibrary(tester);

      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
      expect(find.text('Kidus Kidus'), findsOneWidget);
      expect(find.text('ቅዱስ ቅዱስ ቅዱስ'), findsOneWidget);
      expect(find.textContaining('ሊቀ መዘምራን ይልማ ኃይሉ ·'), findsOneWidget);
      // No title tag: the file name, and no artist.
      expect(find.text('untagged_mezmur'), findsOneWidget);
      expect(find.textContaining('${_l10n.unknownArtist} ·'), findsOneWidget);
      // Shorter than 30 s.
      expect(find.text('Voice 001'), findsNothing);
    });

    testWidgets('scans automatically at app start, on any tab', (tester) async {
      final scanner = FakeLibraryScanner(_testFiles());
      await pumpZemaApp(
        tester,
        libraryScanner: scanner,
        savedPrefs: _explained,
      );

      expect(scanner.scans, 1);
    });

    testWidgets('shows progress while the first scan runs', (tester) async {
      final scanner = _HeldScanner(_testFiles());
      await _pumpLibrary(tester, scanner: scanner, settle: false);
      await tester.pump();
      await tester.pump();

      expect(find.text(_l10n.libraryScanning), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      scanner.finish();
      await tester.pumpAndSettle();
      expect(find.text(_l10n.libraryScanning), findsNothing);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
    });

    testWidgets('an empty phone shows No music found', (tester) async {
      await _pumpLibrary(tester, scanner: FakeLibraryScanner());

      expect(_emptyState(tester).title, _l10n.libraryEmptyTitle);
      expect(_emptyState(tester).kind, EmptyStateKind.empty);
    });

    testWidgets('a failed first scan offers Try again', (tester) async {
      final scanner = FakeLibraryScanner(_testFiles())
        ..error = const ScanFailure('boom');
      await _pumpLibrary(tester, scanner: scanner);

      expect(_emptyState(tester).kind, EmptyStateKind.error);
      expect(_emptyState(tester).title, _l10n.libraryScanFailedTitle);

      scanner.error = null;
      await tester.tap(find.text(_l10n.actionTryAgain));
      await tester.pumpAndSettle();

      expect(scanner.scans, 2);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
    });

    testWidgets('a failed rescan keeps the list and shows a snackbar', (
      tester,
    ) async {
      final scanner = FakeLibraryScanner(_testFiles());
      await _pumpLibrary(tester, scanner: scanner);

      scanner.error = const ScanFailure('boom');
      await _rescan(tester);

      expect(find.text(_l10n.libraryScanFailedSnack), findsOneWidget);
      expect(find.text('Kidus Kidus'), findsOneWidget);
    });

    testWidgets('fits light and dark at 1.3× text on a small phone', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 568), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pumpLibrary(tester, phoneBrightness: brightness);

        expect(tester.takeException(), isNull, reason: '$brightness');
        final colors = tester.element(find.text('Kidus Kidus')).zemaColors;
        expect(
          colors,
          brightness == Brightness.dark
              ? ZemaColors.nightVigil
              : ZemaColors.nightVigilLight,
        );
        await tester.pumpWidget(const SizedBox());
      }

      await _pumpLibrary(
        tester,
        permissions: FakeAudioPermissionService(current: AudioAccess.denied),
        savedPrefs: {},
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// Starts a rescan through the app's provider scope, as the snackbar's Try
/// again does.
Future<void> _rescan(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LibraryScreen)),
  );
  await container.read(librarySyncProvider.notifier).sync();
  await tester.pumpAndSettle();
}
