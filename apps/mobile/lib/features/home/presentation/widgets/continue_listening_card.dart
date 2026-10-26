import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/format_duration.dart';
import '../../../library/application/library_providers.dart';
import '../../../library/presentation/widgets/track_art.dart';
import '../../../player/application/player_providers.dart';
import 'home_section_header.dart';

/// The song that was loaded when the app last closed, with where it will
/// resume. Shown only while that song is paused and still in the library.
class ContinueListeningCard extends ConsumerWidget {
  const ContinueListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final playing =
        ref.watch(playerStateProvider.select((s) => s.value?.playing)) ?? false;
    final inLibrary =
        track != null &&
        (ref.watch(libraryTracksProvider).value?.any((t) => t.id == track.id) ??
            false);
    if (track == null || playing || !inLibrary) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    // The card starts listening only once the song is paused, and a paused
    // player sends no position updates; until one comes, ask the player.
    final position =
        ref.watch(positionProvider).value ??
        ref.read(audioHandlerProvider).position;
    void resume() => unawaited(ref.read(playerControllerProvider).togglePlay());
    final shape = BorderRadius.circular(ZemaRadius.small);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(title: l10n.homeContinueListening),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
          ),
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: shape,
              side: BorderSide(color: colors.line),
            ),
            child: InkWell(
              borderRadius: shape,
              onTap: resume,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    TrackArt(track: track, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.text,
                              ),
                            ),
                            Text(
                              l10n.homeResumeFrom(formatDuration(position)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: l10n.homeResume,
                      onPressed: resume,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        minimumSize: const Size(
                          ZemaSpacing.minTap,
                          ZemaSpacing.minTap,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
