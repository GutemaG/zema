import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../catalog/application/catalog_index.dart';
import '../../../library/application/library_tab_request.dart';
import '../../../library/application/play_history.dart';
import '../../../library/application/playlists.dart';
import '../../../library/presentation/widgets/playlist_collage.dart';
import '../../../library/presentation/widgets/track_art.dart';
import '../../../player/application/player_providers.dart';
import 'home_section_header.dart';

/// The catalog's newest songs, with a Synced or Text only badge; tapping
/// one opens Song detail in the Home tab. Hidden while the index is empty.
class CommunityLyricsRow extends ConsumerWidget {
  const CommunityLyricsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(newLyricsProvider);
    if (songs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return _HomeRow(
      header: HomeSectionHeader(title: l10n.homeNewLyrics),
      cards: [
        for (final song in songs)
          _HomeCard(
            key: ValueKey(song.id),
            art: Stack(
              children: [
                ExcludeSemantics(
                  child: LetterTile(label: song.title, size: _cardArt),
                ),
                PositionedDirectional(
                  start: 6,
                  bottom: 6,
                  child: _SyncBadge(synced: song.synced),
                ),
              ],
            ),
            title: song.title,
            subtitle: song.artist,
            onTap: () =>
                context.go(AppRoutes.song(song.id, base: AppRoutes.home)),
          ),
      ],
    );
  }
}

/// "Synced" in the design system's badge colours, or "Text only" muted.
class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: synced ? colors.soft : colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          synced ? l10n.songRecordingSynced : l10n.songRecordingTextOnly,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: synced ? colors.accentText : colors.muted),
        ),
      ),
    );
  }
}

/// Square art size of a card in a Home row.
const _cardArt = 120.0;

/// The latest plays; tapping one plays the row from it.
class RecentlyPlayedRow extends ConsumerWidget {
  const RecentlyPlayedRow({super.key});

  static const maxSongs = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent =
        ref
            .watch(autoPlaylistProvider(AutoPlaylistKind.recentlyPlayed))
            .value
            ?.take(maxSongs)
            .toList() ??
        const [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return _HomeRow(
      header: HomeSectionHeader(
        title: AppLocalizations.of(context).homeRecentlyPlayed,
        onSeeAll: () =>
            context.go(AppRoutes.autoPlaylist(AutoPlaylistKind.recentlyPlayed)),
      ),
      cards: [
        for (final (index, track) in recent.indexed)
          _HomeCard(
            key: ValueKey(track.id),
            art: TrackArt(track: track, size: _cardArt),
            title: track.title,
            subtitle: track.artist,
            onTap: () => unawaited(
              ref.read(playerControllerProvider).playList(recent, start: index),
            ),
          ),
      ],
    );
  }
}

/// The user's playlists; tapping one opens it.
class PlaylistsRow extends ConsumerWidget {
  const PlaylistsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    if (playlists.isEmpty) return const SizedBox.shrink();
    return _HomeRow(
      header: HomeSectionHeader(
        title: l10n.homeYourPlaylists,
        onSeeAll: () {
          ref
              .read(libraryTabRequestProvider.notifier)
              .open(LibraryTab.playlists);
          context.go(AppRoutes.library);
        },
      ),
      cards: [
        for (final playlist in playlists)
          _HomeCard(
            key: ValueKey(playlist.id),
            art: PlaylistCollage(playlist: playlist, size: _cardArt),
            title: playlist.name,
            subtitle: l10n.librarySongCount(playlist.tracks.length),
            onTap: () => context.go(AppRoutes.playlist(playlist.id)),
          ),
      ],
    );
  }
}

class _HomeRow extends StatelessWidget {
  const _HomeRow({required this.header, required this.cards});

  final Widget header;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        // A Row in a scroll view rather than a ListView: at most a few dozen
        // cards, and the row takes its height from the text scale.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide - 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards,
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget art;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ZemaRadius.small),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SizedBox(
              width: _cardArt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  art,
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: colors.text),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
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
