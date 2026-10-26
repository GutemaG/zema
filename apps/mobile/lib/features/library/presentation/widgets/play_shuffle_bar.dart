import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/player_providers.dart';

/// A [label] (usually the song count), any extra [actions], then Shuffle
/// and Play for [tracks]. Both buttons are disabled when [tracks] is empty.
class PlayShuffleBar extends ConsumerWidget {
  const PlayShuffleBar({
    super.key,
    required this.label,
    required this.tracks,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(ZemaSpacing.screenSide, 4, 8, 4),
  });

  final String label;
  final List<Track> tracks;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final player = ref.read(playerControllerProvider);
    final enabled = tracks.isNotEmpty;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.muted),
            ),
          ),
          ...actions,
          IconButton(
            tooltip: l10n.actionShuffle,
            icon: Icon(Icons.shuffle, color: colors.text),
            onPressed: enabled
                ? () => unawaited(player.shuffleList(tracks))
                : null,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: enabled
                ? () => unawaited(player.playList(tracks))
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.actionPlay),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(ZemaSpacing.minTap, ZemaSpacing.minTap),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
