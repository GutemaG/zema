import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/library_access_controller.dart';

/// Shows [child] once audio access is granted; until then the explanation,
/// denied, settings-only or unsupported state (shared by Home and Library).
class LibraryAccessGate extends ConsumerWidget {
  const LibraryAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(libraryAccessProvider)) {
      AsyncData(value: LibraryAccess.granted) => child,
      AsyncData(:final value) => _AccessState(access: value),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
        actionLabel: l10n.actionTryAgain,
        onAction: () => ref.invalidate(libraryAccessProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Explanation, denied, settings-only and unsupported states.
class _AccessState extends ConsumerWidget {
  const _AccessState({required this.access});

  final LibraryAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(libraryAccessProvider.notifier);
    return switch (access) {
      LibraryAccess.needsExplanation => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.library_music_outlined,
        title: l10n.libraryAccessTitle,
        message: l10n.libraryAccessMessage,
        actionLabel: l10n.libraryAccessAllow,
        onAction: controller.allow,
        secondaryActionLabel: l10n.libraryAccessNotNow,
        onSecondaryAction: controller.notNow,
      ),
      LibraryAccess.denied => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.music_off_outlined,
        title: l10n.libraryAccessDeniedTitle,
        message: l10n.libraryAccessDeniedMessage,
        actionLabel: l10n.libraryAccessGrant,
        onAction: controller.allow,
      ),
      LibraryAccess.permanentlyDenied => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.music_off_outlined,
        title: l10n.libraryAccessDeniedTitle,
        message: l10n.libraryAccessSettingsMessage,
        actionLabel: l10n.libraryAccessOpenSettings,
        onAction: controller.openSettings,
      ),
      LibraryAccess.unsupported => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.phone_iphone,
        title: l10n.libraryUnsupportedTitle,
        message: l10n.libraryUnsupportedMessage,
      ),
      // Handled by LibraryAccessGate.
      LibraryAccess.granted => const SizedBox.shrink(),
    };
  }
}
