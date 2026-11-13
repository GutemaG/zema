import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/lyrics_overlay.dart';
import 'detection_providers.dart';
import 'lyrics_overlay_sync.dart';

enum DetectionApp {
  youtube('YouTube', {'com.google.android.youtube'}),
  youtubeMusic('YouTube Music', {'com.google.android.apps.youtube.music'}),
  telegram('Telegram', {
    'org.telegram.messenger',
    'org.telegram.messenger.web',
    'org.thunderdog.challegram',
  });

  const DetectionApp(this.label, this.packages);

  final String label;
  final Set<String> packages;

  static String labelOf(String package) =>
      values
          .where((app) => app.packages.contains(package))
          .firstOrNull
          ?.label ??
      package;
}

@immutable
class DetectionSettings {
  const DetectionSettings({
    required this.enabled,
    required this.sources,
    required this.appearance,
  });

  final bool enabled;
  final Set<String> sources;
  final OverlayAppearance appearance;

  bool watches(DetectionApp app) => app.packages.any(sources.contains);

  DetectionSettings copyWith({
    bool? enabled,
    Set<String>? sources,
    OverlayAppearance? appearance,
  }) => DetectionSettings(
    enabled: enabled ?? this.enabled,
    sources: sources ?? this.sources,
    appearance: appearance ?? this.appearance,
  );
}

final detectionSettingsProvider =
    AsyncNotifierProvider<DetectionSettingsController, DetectionSettings>(
      DetectionSettingsController.new,
    );

class DetectionSettingsController extends AsyncNotifier<DetectionSettings> {
  @override
  Future<DetectionSettings> build() async {
    final detector = ref.watch(playbackDetectorProvider);
    final overlay = ref.watch(lyricsOverlayProvider);
    return DetectionSettings(
      enabled: await detector.enabled(),
      sources: await detector.sources(),
      appearance: await overlay.appearance(),
    );
  }

  Future<void> setEnabled(bool on) async {
    final current = await future;
    state = AsyncData(current.copyWith(enabled: on));
    await ref.read(playbackDetectorProvider).setEnabled(on);
  }

  Future<void> setApp(DetectionApp app, bool on) async {
    final current = await future;
    final sources = on
        ? {...current.sources, ...app.packages}
        : current.sources.difference(app.packages);
    state = AsyncData(current.copyWith(sources: sources));
    await ref.read(playbackDetectorProvider).setSources(sources);
  }

  Future<void> setAppearance(OverlayAppearance appearance) async {
    final current = await future;
    state = AsyncData(current.copyWith(appearance: appearance));
    await ref.read(lyricsOverlayProvider).setAppearance(appearance);
    ref.invalidate(overlayStartProvider);
  }
}

abstract interface class MicrophoneAccess {
  Future<bool> granted();

  Future<void> fix();
}

class PermissionMicrophoneAccess implements MicrophoneAccess {
  const PermissionMicrophoneAccess();

  @override
  Future<bool> granted() => Permission.microphone.isGranted;

  @override
  Future<void> fix() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) await openAppSettings();
  }
}

final microphoneAccessProvider = Provider<MicrophoneAccess>(
  (ref) => const PermissionMicrophoneAccess(),
);

final microphoneGrantedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(microphoneAccessProvider).granted(),
);
