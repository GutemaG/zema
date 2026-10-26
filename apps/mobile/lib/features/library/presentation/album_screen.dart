import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/album_grouping.dart';
import '../application/library_groups.dart';
import 'song_menu.dart';
import 'widgets/album_tile.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/track_art.dart';
import 'widgets/track_row.dart';

/// "48 min" or "1 h 12 min".
String formatTotalDuration(AppLocalizations l10n, Duration duration) {
  final minutes = (duration.inSeconds / 60).round();
  return minutes < 60
      ? l10n.durationMinutes(minutes)
      : l10n.durationHoursMinutes(minutes ~/ 60, minutes % 60);
}

/// S12a: cover, name, artist, "year · songs · total duration", Play and
/// Shuffle, and the numbered track list. Shows C07 when the album is no
/// longer in the library (or [id] is null: a malformed link).
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.id});

  final AlbumId? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final albums = ref.watch(albumsProvider);
    final album = albums.value?.where((a) => a.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(),
      body: switch (albums) {
        AsyncData() when album != null => _AlbumBody(album: album),
        AsyncData() => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.album_outlined,
          title: l10n.albumGoneTitle,
          message: l10n.albumGoneMessage,
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

class _AlbumBody extends ConsumerWidget {
  const _AlbumBody({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final tracks = album.tracks;
    final title = albumTitle(l10n, album);
    final info = [
      if (album.year case final year?) '$year',
      l10n.librarySongCount(tracks.length),
      formatTotalDuration(l10n, album.duration),
    ].join(' · ');
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              0,
              ZemaSpacing.screenSide,
              8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cover = min(220.0, constraints.maxWidth * 0.6);
                return Column(
                  children: [
                    TrackArt(
                      track: album.cover,
                      size: cover,
                      radius: 16,
                      label: title,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      albumArtist(l10n, album),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.primaryText,
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
        SliverToBoxAdapter(
          child: PlayShuffleBar(
            label: l10n.librarySongCount(tracks.length),
            tracks: tracks,
          ),
        ),
        SliverFixedExtentList(
          itemExtent: TrackRow.height,
          delegate: SliverChildBuilderDelegate(childCount: tracks.length, (
            context,
            index,
          ) {
            final track = tracks[index];
            return TrackRow(
              key: ValueKey(track.id),
              track: track,
              number: index + 1,
              isCurrent: track.id == currentId,
              onTap: () => unawaited(player.playList(tracks, start: index)),
              trailing: SongMenuButton(track: track),
            );
          }),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: ZemaSpacing.screenSide),
        ),
      ],
    );
  }
}
