import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';
import '../application/library_access_controller.dart';
import '../application/library_providers.dart';
import '../application/library_sync_controller.dart';

/// The Library tab: audio access first, then the phone's tracks.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final access = ref.watch(libraryAccessProvider);
    return TabPage(
      title: l10n.navLibrary,
      child: switch (access) {
        AsyncData(value: LibraryAccess.granted) => const _LibraryContent(),
        AsyncData(:final value) => _AccessState(access: value),
        AsyncError() => EmptyState(
          kind: EmptyStateKind.error,
          title: l10n.libraryScanFailedTitle,
          message: l10n.libraryScanFailedMessage,
          actionLabel: l10n.actionTryAgain,
          onAction: () => ref.invalidate(libraryAccessProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
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
      // Handled by LibraryScreen.
      LibraryAccess.granted => const SizedBox.shrink(),
    };
  }
}

/// Stored tracks, the first-scan progress, and scan failures.
class _LibraryContent extends ConsumerWidget {
  const _LibraryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sync = ref.watch(librarySyncProvider);
    final tracks = ref.watch(libraryTracksProvider);

    ref.listen(librarySyncProvider, (previous, next) {
      final hasTracks = ref.read(libraryTracksProvider).value?.isNotEmpty;
      if (next.hasFailed && previous?.hasFailed != true && hasTracks == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.libraryScanFailedSnack),
            action: SnackBarAction(
              label: l10n.actionTryAgain,
              onPressed: ref.read(librarySyncProvider.notifier).sync,
            ),
          ),
        );
      }
    });

    void retry() => ref.read(librarySyncProvider.notifier).sync();

    return switch (tracks) {
      AsyncData(:final value) when value.isNotEmpty => _TrackList(
        tracks: value,
      ),
      AsyncData() when sync.hasFailed => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
        actionLabel: l10n.actionTryAgain,
        onAction: retry,
      ),
      AsyncData() when sync.lastResult != null && !sync.isScanning =>
        EmptyState(
          kind: EmptyStateKind.empty,
          title: l10n.libraryEmptyTitle,
          message: l10n.libraryEmptyMessage,
        ),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
        actionLabel: l10n.actionTryAgain,
        onAction: () => ref.invalidate(libraryTracksProvider),
      ),
      // Loading, or nothing stored yet while the first scan runs.
      _ => _Scanning(label: l10n.libraryScanning),
    };
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZemaSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.accent),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Temporary plain list; bolt 005 replaces it with the Tracks screen (S10).
class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return ListView.builder(
      itemCount: tracks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              8,
              ZemaSpacing.screenSide,
              8,
            ),
            child: Text(
              l10n.librarySongCount(tracks.length),
              style: textTheme.labelLarge?.copyWith(color: colors.muted),
            ),
          );
        }
        final track = tracks[index - 1];
        return ListTile(
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist ?? l10n.unknownArtist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted),
          ),
        );
      },
    );
  }
}
