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
import '../application/artist_grouping.dart';
import '../application/library_groups.dart';
import 'artists_view.dart';
import 'song_menu.dart';
import 'widgets/album_tile.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/track_art.dart';
import 'widgets/track_row.dart';

/// S13a: an artist's avatar and name, Play and Shuffle, their albums (a row
/// of covers that open S12a) and their songs. [known] false is "Unknown
/// artist". Shows C07 when the artist is no longer in the library.
class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.name, this.known = true});

  final String? name;
  final bool known;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final artists = ref.watch(artistsProvider);
    final artist = artists.value
        ?.where(
          (a) => known ? a.name != null && a.name == name : a.name == null,
        )
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(),
      body: switch (artists) {
        AsyncData() when artist != null => _ArtistBody(artist: artist),
        AsyncData() => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.person_off_outlined,
          title: l10n.artistGoneTitle,
          message: l10n.artistGoneMessage,
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

class _ArtistBody extends ConsumerWidget {
  const _ArtistBody({required this.artist});

  final Artist artist;

  static const _albumWidth = 140.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final name = artistName(l10n, artist);
    final tracks = artist.tracks;
    final albums = artist.albums;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        16,
        ZemaSpacing.screenSide,
        8,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: colors.text),
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              TrackArt(track: artist.cover, size: 140, radius: 70, label: name),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              PlayShuffleBar(
                label: [
                  l10n.librarySongCount(tracks.length),
                  l10n.albumCount(albums.length),
                ].join(' · '),
                tracks: tracks,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: section(l10n.artistAlbums)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: _albumWidth + AlbumTile.textHeight(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: ZemaSpacing.screenSide,
              ),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final album = albums[index];
                return AlbumTile(
                  album: album,
                  width: _albumWidth,
                  onTap: () => unawaited(
                    context.push(
                      AppRoutes.album(
                        album.id,
                        base: AppRoutes.detailBase(
                          GoRouterState.of(context).uri.path,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(child: section(l10n.artistSongs)),
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
