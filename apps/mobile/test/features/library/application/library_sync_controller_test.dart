import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema/features/library/application/library_sync_controller.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

/// A scanner whose scans finish only when the test says so.
class _SlowScanner extends FakeLibraryScanner {
  final _pending = <Completer<void>>[];

  void finishAll() {
    for (final c in _pending) {
      c.complete();
    }
    _pending.clear();
  }

  @override
  Future<List<ScannedAudio>> scan() async {
    final done = Completer<void>();
    _pending.add(done);
    await done.future;
    return super.scan();
  }
}

Future<ProviderContainer> _container({
  required FakeLibraryScanner scanner,
  required FakeAudioPermissionService permissions,
}) async {
  SharedPreferences.setMockInitialValues({
    LibraryAccessController.explainedKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...libraryOverrides(scanner: scanner, permissions: permissions),
    ],
  );
}

/// The visible tracks. Listens while waiting: Riverpod 3 pauses providers
/// that are only read.
Future<List<Track>> _tracks(ProviderContainer container) =>
    container.listen(libraryTracksProvider.future, (_, _) {}).read();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibrarySyncController', () {
    test('scans on start when access is already granted', () async {
      final scanner = FakeLibraryScanner([scannedAudio(1, '/m/a.mp3')]);
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(),
      );

      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();

      expect(scanner.scans, 1);
      expect(container.read(librarySyncProvider).lastResult?.added, 1);
      expect(await _tracks(container), hasLength(1));
    });

    test('does not scan without access, then scans once granted', () async {
      final scanner = FakeLibraryScanner();
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(current: AudioAccess.denied),
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();
      expect(scanner.scans, 0);

      await container.read(libraryAccessProvider.notifier).allow();
      await pumpEventQueue();

      expect(scanner.scans, 1);
    });

    test('never runs two scans at once', () async {
      final scanner = _SlowScanner();
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(),
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(librarySyncProvider).isScanning, isTrue);

      final again = container.read(librarySyncProvider.notifier).sync();
      await pumpEventQueue();
      expect(scanner.scans, 0); // Still waiting inside the first scan.

      scanner.finishAll();
      await again;

      expect(scanner.scans, 1);
      expect(container.read(librarySyncProvider).isScanning, isFalse);
    });

    test('a failed scan keeps the last result and the library', () async {
      final scanner = FakeLibraryScanner([scannedAudio(1, '/m/a.mp3')]);
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(),
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();

      scanner.error = const ScanFailure('boom');
      await container.read(librarySyncProvider.notifier).sync();

      final state = container.read(librarySyncProvider);
      expect(state.hasFailed, isTrue);
      expect(state.failure, isA<ScanFailure>());
      expect(state.lastResult, isNotNull);
      expect(await _tracks(container), hasLength(1));
    });

    test('a permission failure re-checks access', () async {
      final permissions = FakeAudioPermissionService();
      final scanner = FakeLibraryScanner();
      final container = await _container(
        scanner: scanner,
        permissions: permissions,
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();

      permissions.current = AudioAccess.denied;
      scanner.error = const PermissionFailure('revoked');
      await container.read(librarySyncProvider.notifier).sync();
      await pumpEventQueue();

      expect(container.read(libraryAccessProvider).value, LibraryAccess.denied);
    });

    test('a later sync succeeds after a failure', () async {
      final scanner = FakeLibraryScanner()..error = const ScanFailure('boom');
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(),
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(librarySyncProvider).hasFailed, isTrue);

      scanner
        ..error = null
        ..files = [scannedAudio(1, '/m/a.mp3')];
      await container.read(librarySyncProvider.notifier).sync();

      expect(container.read(librarySyncProvider).hasFailed, isFalse);
      expect(container.read(librarySyncProvider).failure, isNull);
    });

    test('scans again when the app comes back to the foreground', () async {
      final scanner = FakeLibraryScanner([scannedAudio(1, '/m/a.mp3')]);
      final container = await _container(
        scanner: scanner,
        permissions: FakeAudioPermissionService(),
      );
      container.listen(librarySyncProvider, (_, _) {});
      await pumpEventQueue();

      scanner.files = [
        scannedAudio(1, '/m/a.mp3'),
        scannedAudio(2, '/m/b.mp3'),
      ];
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
          state,
        );
      }
      await pumpEventQueue();

      expect(scanner.scans, 2);
      expect(await _tracks(container), hasLength(2));
    });
  });
}
