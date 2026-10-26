import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/playlists.dart';
import 'playlist_dialog.dart';
import 'widgets/playlist_collage.dart';

/// S15: a "Create playlist" card, then the user's playlists by name. The
/// auto playlists section comes with story 019.
class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  Future<void> _create(BuildContext context) async {
    final id = await showPlaylistDialog(context);
    if (id != null && context.mounted) {
      unawaited(context.push(AppRoutes.playlist(id)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    return switch (ref.watch(playlistsProvider)) {
      AsyncData(value: final playlists) => ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: playlists.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PlaylistTile(
              leading: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox.square(
                  dimension: _PlaylistTile.artSize,
                  child: Icon(Icons.add, color: colors.primaryText),
                ),
              ),
              title: l10n.playlistCreate,
              subtitle: l10n.playlistCreateHint,
              onTap: () => unawaited(_create(context)),
            );
          }
          final playlist = playlists[index - 1];
          return _PlaylistTile(
            key: ValueKey(playlist.id),
            leading: PlaylistCollage(
              playlist: playlist,
              size: _PlaylistTile.artSize,
            ),
            title: playlist.name,
            subtitle: l10n.librarySongCount(playlist.tracks.length),
            onTap: () =>
                unawaited(context.push(AppRoutes.playlist(playlist.id))),
          );
        },
      ),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const artSize = 56.0;

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZemaSpacing.screenSide,
              vertical: 6,
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
