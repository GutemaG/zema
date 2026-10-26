import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../library/application/library_tab_request.dart';
import '../../../library/application/play_history.dart';
import '../../../player/application/player_providers.dart';

/// Shuffle all, Favorites, Recently added and Playlists, two per row.
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key, required this.tracks});

  /// The visible library, for Shuffle all.
  final List<Track> tracks;

  void _openLibraryTab(BuildContext context, WidgetRef ref, LibraryTab tab) {
    ref.read(libraryTabRequestProvider.notifier).open(tab);
    context.go(AppRoutes.library);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      _QuickAction(
        icon: Icons.shuffle,
        label: l10n.homeShuffleAll,
        onTap: tracks.isEmpty
            ? null
            : () => unawaited(
                ref.read(playerControllerProvider).shuffleList(tracks),
              ),
      ),
      _QuickAction(
        icon: Icons.favorite_border,
        label: l10n.libraryTabFavorites,
        onTap: () => _openLibraryTab(context, ref, LibraryTab.favorites),
      ),
      _QuickAction(
        icon: Icons.new_releases_outlined,
        label: l10n.autoRecentlyAdded,
        onTap: () =>
            context.go(AppRoutes.autoPlaylist(AutoPlaylistKind.recentlyAdded)),
      ),
      _QuickAction(
        icon: Icons.queue_music,
        label: l10n.libraryTabPlaylists,
        onTap: () => _openLibraryTab(context, ref, LibraryTab.playlists),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        12,
        ZemaSpacing.screenSide,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final action in actions)
                SizedBox(width: width, child: action),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;

  /// Null disables the tile.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final enabled = onTap != null;
    final shape = BorderRadius.circular(ZemaRadius.small);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: colors.line),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: enabled ? colors.primaryText : colors.faint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? colors.text : colors.faint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
