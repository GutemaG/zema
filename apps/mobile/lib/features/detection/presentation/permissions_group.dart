import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../library/application/library_access_controller.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/detection_providers.dart';
import '../application/detection_settings.dart';
import '../application/lyrics_overlay_sync.dart';

class PermissionsGroup extends ConsumerStatefulWidget {
  const PermissionsGroup({super.key, this.music = false});

  final bool music;

  @override
  ConsumerState<PermissionsGroup> createState() => _PermissionsGroupState();
}

class _PermissionsGroupState extends ConsumerState<PermissionsGroup> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref
          ..invalidate(detectionAccessProvider)
          ..invalidate(overlayAccessProvider)
          ..invalidate(microphoneGrantedProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otherApps = ref.watch(otherAppsSupportedProvider);

    Widget row(String label, bool? granted, Future<void> Function() fix) =>
        SettingsRow(
          key: ValueKey(label),
          label: label,
          value: granted == true ? l10n.detectionPermissionAllowed : null,
          trailing: granted == false
              ? TextButton(
                  onPressed: () => unawaited(fix()),
                  child: Text(l10n.detectionPermissionFix),
                )
              : null,
        );

    final library = widget.music
        ? ref.watch(libraryAccessProvider).value
        : null;
    final libraryAccess = ref.read(libraryAccessProvider.notifier);
    return SettingsGroup(
      title: l10n.detectionSectionPermissions,
      children: [
        if (library != null && library != LibraryAccess.unsupported)
          row(
            l10n.onboardingPermissionMusic,
            library == LibraryAccess.granted,
            library == LibraryAccess.permanentlyDenied
                ? libraryAccess.openSettings
                : libraryAccess.allow,
          ),
        row(
          l10n.detectionPermissionMicrophone,
          ref.watch(microphoneGrantedProvider).value,
          () async {
            await ref.read(microphoneAccessProvider).fix();
            ref.invalidate(microphoneGrantedProvider);
          },
        ),
        if (otherApps) ...[
          row(
            l10n.detectionPermissionNotifications,
            ref.watch(detectionAccessProvider).value,
            ref.read(playbackDetectorProvider).openAccessSettings,
          ),
          row(
            l10n.detectionPermissionOverlay,
            ref.watch(overlayAccessProvider).value,
            ref.read(lyricsOverlayProvider).openSettings,
          ),
        ],
      ],
    );
  }
}
