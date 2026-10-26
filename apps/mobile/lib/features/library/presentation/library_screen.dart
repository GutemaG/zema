import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';
import '../application/library_access_controller.dart';
import 'albums_view.dart';
import 'artists_view.dart';
import 'folders_view.dart';
import 'tracks_view.dart';

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
        AsyncData(value: LibraryAccess.granted) => const _LibraryTabs(),
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

/// The top tabs. Favorites and Playlists arrive in a later bolt.
class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final later = [l10n.libraryTabFavorites, l10n.libraryTabPlaylists];
    return DefaultTabController(
      length: later.length + 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            labelColor: colors.primaryText,
            unselectedLabelColor: colors.muted,
            indicatorColor: colors.primary,
            dividerColor: colors.line,
            tabs: [
              Tab(text: l10n.libraryTabTracks),
              Tab(text: l10n.libraryTabFolders),
              Tab(text: l10n.libraryTabAlbums),
              Tab(text: l10n.libraryTabArtists),
              for (final name in later) Tab(text: name),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const TracksView(),
                const FoldersView(),
                const AlbumsView(),
                const ArtistsView(),
                for (final _ in later)
                  EmptyState(
                    kind: EmptyStateKind.empty,
                    title: l10n.comingSoonTitle,
                    message: l10n.libraryTabComingSoon,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
