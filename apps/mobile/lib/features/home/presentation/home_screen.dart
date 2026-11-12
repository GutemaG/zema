import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';
import '../../account/presentation/widgets/profile_button.dart';
import '../../identify/presentation/listen_button.dart';
import '../../library/application/library_providers.dart';
import '../../library/application/library_sync_controller.dart';
import '../../library/presentation/library_access_gate.dart';
import 'widgets/continue_listening_card.dart';
import 'widgets/home_rows.dart';
import 'widgets/quick_actions.dart';

/// S05: quick actions, the song to continue, recent plays and playlists.
/// Each section hides when it has nothing to show.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const tap = BoxConstraints(
      minWidth: ZemaSpacing.minTap,
      minHeight: ZemaSpacing.minTap,
    );
    return TabPage(
      title: l10n.appTitle,
      actions: [
        const ListenButton(),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.homeSearchTooltip,
          constraints: tap,
          onPressed: () => context.go(AppRoutes.search),
        ),
        const ProfileButton(),
      ],
      child: const LibraryAccessGate(child: _HomeBody()),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sync = ref.watch(librarySyncProvider);
    final tracks = ref.watch(libraryTracksProvider);
    void rescan() => ref.read(librarySyncProvider.notifier).sync();

    final stored = tracks.value ?? const <Track>[];
    if (tracks is AsyncData && stored.isEmpty && !sync.isScanning) {
      if (sync.hasFailed) {
        return EmptyState(
          kind: EmptyStateKind.error,
          title: l10n.libraryScanFailedTitle,
          message: l10n.libraryScanFailedMessage,
          actionLabel: l10n.actionTryAgain,
          onAction: rescan,
        );
      }
      if (sync.lastResult != null) {
        return EmptyState(
          kind: EmptyStateKind.empty,
          title: l10n.libraryEmptyTitle,
          message: l10n.libraryEmptyMessage,
          actionLabel: l10n.settingsRescan,
          onAction: rescan,
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        QuickActions(tracks: stored),
        if (stored.isEmpty)
          _Scanning(label: l10n.libraryScanning)
        else ...const [
          ContinueListeningCard(),
          RecentlyPlayedRow(),
          PlaylistsRow(),
          CommunityLyricsRow(),
        ],
      ],
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          CircularProgressIndicator(color: colors.accent),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
