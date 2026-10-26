import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/folder_tree.dart';
import '../application/library_groups.dart';
import 'widgets/folder_row.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/track_row.dart';

/// S11a: a folder's breadcrumb, its subfolders (with the count of every
/// song below them), then its own songs. Play all and Shuffle cover the
/// folder and everything below it.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final index = ref.watch(folderIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName(l10n, path)),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: switch (index) {
        AsyncData(:final value) when !value.contentsOf(path).isEmpty =>
          _Contents(path: path, index: value),
        AsyncData() => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.folder_off_outlined,
          title: l10n.folderGoneTitle,
          message: l10n.folderGoneMessage,
        ),
        AsyncError() => EmptyState(
          kind: EmptyStateKind.error,
          title: l10n.libraryScanFailedTitle,
          message: l10n.libraryScanFailedMessage,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Contents extends ConsumerWidget {
  const _Contents({required this.path, required this.index});

  final String path;
  final FolderIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contents = index.contentsOf(path);
    final all = index.tracksUnder(path);
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final subfolders = contents.subfolders;
    final tracks = contents.tracks;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Breadcrumb(path: path)),
        SliverToBoxAdapter(
          child: PlayShuffleBar(
            label: l10n.librarySongCount(all.length),
            tracks: all,
          ),
        ),
        SliverFixedExtentList(
          itemExtent: ZemaSpacing.listRow,
          delegate: SliverChildBuilderDelegate(
            childCount: subfolders.length + tracks.length,
            (context, i) {
              if (i < subfolders.length) {
                final folder = subfolders[i];
                return FolderRow(
                  key: ValueKey(folder.path),
                  folder: folder,
                  showPath: false,
                  onTap: () =>
                      unawaited(context.push(AppRoutes.folder(folder.path))),
                );
              }
              final at = i - subfolders.length;
              final track = tracks[at];
              return TrackRow(
                key: ValueKey(track.id),
                track: track,
                isCurrent: track.id == currentId,
                onTap: () => unawaited(player.playList(tracks, start: at)),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// `Phone › Music › Telegram`: each segment but the last opens that folder.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final crumbs = locateFolder(path).breadcrumb;
    const padding = ZemaSpacing.screenSide - 8;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Starts at the end, so the current folder is visible.
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: padding),
        // At least as wide as the screen, so a short path starts on the left.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth - 2 * padding,
          ),
          child: Row(
            children: [
              for (var i = 0; i < crumbs.length; i++) ...[
                if (i > 0)
                  Icon(Icons.chevron_right, size: 18, color: colors.faint),
                if (i == crumbs.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      folderName(l10n, crumbs[i]),
                      style: textTheme.labelLarge?.copyWith(color: colors.text),
                    ),
                  )
                else
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.muted,
                      minimumSize: const Size(
                        ZemaSpacing.minTap,
                        ZemaSpacing.minTap,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => context.go(AppRoutes.folder(crumbs[i])),
                    child: Text(folderName(l10n, crumbs[i])),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
