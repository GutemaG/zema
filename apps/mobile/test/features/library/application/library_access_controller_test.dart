import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';

import '../../../helpers/fake_library.dart';

Future<ProviderContainer> _container(
  FakeAudioPermissionService permissions, {
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioPermissionServiceProvider.overrideWithValue(permissions),
    ],
  );
}

const _explained = {LibraryAccessController.explainedKey: true};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryAccessController', () {
    test('asks for the explanation first when never asked', () async {
      final container = await _container(
        FakeAudioPermissionService(current: AudioAccess.denied),
      );

      expect(
        await container.read(libraryAccessProvider.future),
        LibraryAccess.needsExplanation,
      );
    });

    test('goes straight to denied once the explanation was seen', () async {
      final container = await _container(
        FakeAudioPermissionService(current: AudioAccess.denied),
        saved: _explained,
      );

      expect(
        await container.read(libraryAccessProvider.future),
        LibraryAccess.denied,
      );
    });

    test('reports granted and unsupported as they are', () async {
      for (final (access, expected) in [
        (AudioAccess.granted, LibraryAccess.granted),
        (AudioAccess.unsupported, LibraryAccess.unsupported),
        (AudioAccess.permanentlyDenied, LibraryAccess.permanentlyDenied),
      ]) {
        final container = await _container(
          FakeAudioPermissionService(current: access),
        );
        expect(
          await container.read(libraryAccessProvider.future),
          expected,
          reason: '$access',
        );
      }
    });

    test(
      'Allow shows the dialog, remembers the explanation and grants',
      () async {
        final permissions = FakeAudioPermissionService(
          current: AudioAccess.denied,
        );
        final container = await _container(permissions);
        await container.read(libraryAccessProvider.future);

        await container.read(libraryAccessProvider.notifier).allow();

        expect(permissions.requests, 1);
        expect(
          container.read(libraryAccessProvider).value,
          LibraryAccess.granted,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(LibraryAccessController.explainedKey), isTrue);
      },
    );

    test(
      'a denial in the dialog leads to denied, not the explanation',
      () async {
        final container = await _container(
          FakeAudioPermissionService(
            current: AudioAccess.denied,
            onRequest: AudioAccess.denied,
          ),
        );
        await container.read(libraryAccessProvider.future);

        await container.read(libraryAccessProvider.notifier).allow();

        expect(
          container.read(libraryAccessProvider).value,
          LibraryAccess.denied,
        );
      },
    );

    test('Not now leads to denied without asking the system', () async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.denied,
      );
      final container = await _container(permissions);
      await container.read(libraryAccessProvider.future);

      await container.read(libraryAccessProvider.notifier).notNow();

      expect(permissions.requests, 0);
      expect(container.read(libraryAccessProvider).value, LibraryAccess.denied);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(LibraryAccessController.explainedKey), isTrue);
    });

    test(
      'keeps a permanent denial when a later check only says denied',
      () async {
        final permissions = FakeAudioPermissionService(
          current: AudioAccess.denied,
          onRequest: AudioAccess.permanentlyDenied,
        );
        final container = await _container(permissions, saved: _explained);
        await container.read(libraryAccessProvider.future);
        await container.read(libraryAccessProvider.notifier).allow();

        permissions.current = AudioAccess.denied;
        await container.read(libraryAccessProvider.notifier).refresh();

        expect(
          container.read(libraryAccessProvider).value,
          LibraryAccess.permanentlyDenied,
        );
      },
    );

    test('Open settings opens the system settings', () async {
      final permissions = FakeAudioPermissionService(
        current: AudioAccess.permanentlyDenied,
      );
      final container = await _container(permissions);
      await container.read(libraryAccessProvider.future);

      await container.read(libraryAccessProvider.notifier).openSettings();

      expect(permissions.settingsOpened, 1);
    });

    test(
      'notices access granted in the settings when the app resumes',
      () async {
        final permissions = FakeAudioPermissionService(
          current: AudioAccess.permanentlyDenied,
        );
        final container = await _container(permissions, saved: _explained);
        await container.read(libraryAccessProvider.future);

        permissions.current = AudioAccess.granted;
        final binding = TestWidgetsFlutterBinding.instance;
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          binding.handleAppLifecycleStateChanged(state);
        }
        await pumpEventQueue();

        expect(
          container.read(libraryAccessProvider).value,
          LibraryAccess.granted,
        );
      },
    );

    test('notices access revoked when the app resumes', () async {
      final permissions = FakeAudioPermissionService();
      final container = await _container(permissions, saved: _explained);
      await container.read(libraryAccessProvider.future);

      permissions.current = AudioAccess.denied;
      await container.read(libraryAccessProvider.notifier).refresh();

      expect(container.read(libraryAccessProvider).value, LibraryAccess.denied);
    });
  });
}
