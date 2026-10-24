import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';
import '../data/audio_permission_service.dart';
import 'library_providers.dart';

/// What the Library tab should show about audio access.
enum LibraryAccess {
  /// Never asked: explain why before showing the system dialog.
  needsExplanation,

  /// Not granted; "Grant access" asks again.
  denied,

  /// Not granted and the system won't ask again; only the app's system
  /// settings can grant it.
  permanentlyDenied,
  granted,

  /// No library on this platform (iOS for now).
  unsupported,
}

final libraryAccessProvider =
    AsyncNotifierProvider<LibraryAccessController, LibraryAccess>(
      LibraryAccessController.new,
    );

/// Tracks audio access and re-checks it whenever the app returns to the
/// foreground (e.g. from the system settings).
class LibraryAccessController extends AsyncNotifier<LibraryAccess> {
  /// Saved once the explanation was shown, so it is not shown again.
  static const explainedKey = 'libraryAccessExplained';

  AudioPermissionService get _service =>
      ref.read(audioPermissionServiceProvider);

  bool get _explained =>
      ref.read(sharedPreferencesProvider).getBool(explainedKey) ?? false;

  @override
  Future<LibraryAccess> build() async {
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refresh()),
    );
    ref.onDispose(lifecycle.dispose);
    return _resolve(await _service.status());
  }

  /// Shows the system dialog (from the explanation's "Allow" or from
  /// "Grant access").
  Future<void> allow() async {
    await _markExplained();
    final access = await _service.request();
    if (ref.mounted) state = AsyncData(_resolve(access));
  }

  /// The explanation's "Not now".
  Future<void> notNow() async {
    await _markExplained();
    if (ref.mounted) state = const AsyncData(LibraryAccess.denied);
  }

  Future<void> openSettings() => _service.openSettings();

  /// Re-reads the system status, keeping a known permanent denial (the
  /// system reports it as a plain denial when only checking).
  Future<void> refresh() async {
    final access = await _service.status();
    if (!ref.mounted) return;
    final next = _resolve(access, previous: state.value);
    if (next != state.value) state = AsyncData(next);
  }

  LibraryAccess _resolve(AudioAccess access, {LibraryAccess? previous}) =>
      switch (access) {
        AudioAccess.granted => LibraryAccess.granted,
        AudioAccess.unsupported => LibraryAccess.unsupported,
        AudioAccess.permanentlyDenied => LibraryAccess.permanentlyDenied,
        AudioAccess.denied when previous == LibraryAccess.permanentlyDenied =>
          LibraryAccess.permanentlyDenied,
        AudioAccess.denied =>
          _explained ? LibraryAccess.denied : LibraryAccess.needsExplanation,
      };

  Future<void> _markExplained() async {
    if (!_explained) {
      await ref.read(sharedPreferencesProvider).setBool(explainedKey, true);
    }
  }
}
