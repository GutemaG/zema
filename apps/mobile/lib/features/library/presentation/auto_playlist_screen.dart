import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/play_history.dart';
import 'album_screen.dart';
import 'song_menu.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/track_row.dart';

String autoPlaylistName(AppLocalizations l10n, AutoPlaylistKind kind) =>
    switch (kind) {
      AutoPlaylistKind.recentlyAdded => l10n.autoRecentlyAdded,
      AutoPlaylistKind.mostPlayed => l10n.autoMostPlayed,
      AutoPlaylistKind.recentlyPlayed => l10n.autoRecentlyPlayed,
    };

/// An auto playlist's cover: its icon on a tile.
class AutoPlaylistIcon extends StatelessWidget {
  const AutoPlaylistIcon({
    super.key,
    required this.kind,
    required this.size,
    this.radius = 8,
  });

  final AutoPlaylistKind kind;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tile,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            switch (kind) {
              AutoPlaylistKind.recentlyAdded => Icons.new_releases_outlined,
              AutoPlaylistKind.mostPlayed => Icons.trending_up,
              AutoPlaylistKind.recentlyPlayed => Icons.history,
            },
            size: size * 0.45,
            color: colors.tileFg,
          ),
        ),
      ),
    );
  }
}

/// An auto playlist: icon, name, "songs · duration", Play and Shuffle, then
/// the songs. Read-only: no reorder, remove, rename or Add songs. Shows C07
/// when empty, or when [kind] is null (a malformed link).
class AutoPlaylistScreen extends ConsumerWidget {
  const AutoPlaylistScreen({super.key, required this.kind});

  final AutoPlaylistKind? kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = this.kind;
    return Scaffold(
      appBar: AppBar(),
      body: kind == null
          ? EmptyState(
              kind: EmptyStateKind.empty,
              title: l10n.errorNotFoundTitle,
              message: l10n.errorNotFoundMessage,
            )
          : switch (ref.watch(autoPlaylistProvider(kind))) {
              AsyncData(:final value) => _AutoPlaylistBody(
                kind: kind,
                tracks: value,
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

class _AutoPlaylistBody extends ConsumerWidget {
  const _AutoPlaylistBody({required this.kind, required this.tracks});

  final AutoPlaylistKind kind;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final duration = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final info = [
      l10n.librarySongCount(tracks.length),
      if (tracks.isNotEmpty) formatTotalDuration(l10n, duration),
    ].join(' · ');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              0,
              ZemaSpacing.screenSide,
              12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cover = min(160.0, constraints.maxWidth * 0.45);
                return Column(
                  children: [
                    AutoPlaylistIcon(kind: kind, size: cover, radius: 16),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        autoPlaylistName(l10n, kind),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (tracks.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              kind: EmptyStateKind.empty,
              icon: Icons.queue_music,
              title: kind == AutoPlaylistKind.recentlyAdded
                  ? l10n.autoRecentlyAddedEmptyTitle
                  : l10n.autoPlayedEmptyTitle,
              message: switch (kind) {
                AutoPlaylistKind.recentlyAdded =>
                  l10n.autoRecentlyAddedEmptyMessage,
                AutoPlaylistKind.mostPlayed => l10n.autoMostPlayedEmptyMessage,
                AutoPlaylistKind.recentlyPlayed =>
                  l10n.autoRecentlyPlayedEmptyMessage,
              },
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: PlayShuffleBar(
              label: l10n.librarySongCount(tracks.length),
              tracks: tracks,
            ),
          ),
          SliverFixedExtentList.builder(
            itemExtent: TrackRow.height,
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return TrackRow(
                key: ValueKey(track.id),
                track: track,
                isCurrent: track.id == currentId,
                onTap: () => unawaited(player.playList(tracks, start: index)),
                trailing: SongMenuButton(track: track),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: ZemaSpacing.screenSide),
          ),
        ],
      ],
    );
  }
}
