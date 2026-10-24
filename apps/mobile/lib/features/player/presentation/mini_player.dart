import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/presentation/widgets/track_art.dart';
import '../application/player_providers.dart';
import 'player_progress.dart';

/// C01: the current song above the bottom navigation, on every tab. Tapping
/// it opens Now Playing. Hidden while nothing is loaded.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  static const double height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerStateProvider).value;
    final track = snapshot?.current;
    if (snapshot == null || track == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final player = ref.read(playerControllerProvider);
    final artist = track.artist ?? l10n.unknownArtist;

    return Material(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerProgressLine(duration: snapshot.duration ?? track.duration),
          SizedBox(
            height: height,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: l10n.playerMiniLabel(track.title, artist),
                    hint: l10n.playerOpen,
                    excludeSemantics: true,
                    onTap: () => context.push(AppRoutes.nowPlaying),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.nowPlaying),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: ZemaSpacing.screenSide - 4,
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: playerArtHeroTag,
                              child: TrackArt(track: track, size: 44),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    artist,
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
                ),
                IconButton(
                  tooltip: snapshot.playing
                      ? l10n.playerPause
                      : l10n.playerPlay,
                  icon: Icon(
                    snapshot.playing ? Icons.pause : Icons.play_arrow,
                    color: colors.text,
                  ),
                  onPressed: () => unawaited(player.togglePlay()),
                ),
                IconButton(
                  tooltip: l10n.playerNext,
                  icon: Icon(Icons.skip_next, color: colors.text),
                  onPressed: () => unawaited(player.next()),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared by the mini player and Now Playing so the art flies between them.
const playerArtHeroTag = 'player-art';
