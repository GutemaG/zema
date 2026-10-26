import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/presentation/widgets/track_art.dart';
import '../application/player_providers.dart';
import '../../../shared/format_duration.dart';
import '../data/player_snapshot.dart';
import '../data/sleep_timer.dart';
import 'mini_player.dart';
import 'player_progress.dart';
import 'queue_sheet.dart';
import 'sleep_timer_sheet.dart';

/// S08 (controls only): art, title, artist, seek bar, transport controls,
/// and the sleep timer and queue buttons. The lyrics area says "No lyrics
/// yet" until intent 003. Closes with the down arrow, back, or a swipe down.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final snapshot = ref.watch(playerStateProvider).value;
    final track = snapshot?.current;

    void close() => Navigator.of(context).maybePop();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 400) close();
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.playerClose,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 30,
                        color: colors.text,
                      ),
                      onPressed: close,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.playerNowPlaying,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: ZemaSpacing.minTap + 4),
                  ],
                ),
              ),
              Expanded(
                child: snapshot == null || track == null
                    ? const SizedBox.shrink()
                    : _Body(snapshot: snapshot, track: track),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.snapshot, required this.track});

  final PlayerSnapshot snapshot;
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.biggest.shortestSide;
                return Center(
                  child: Hero(
                    tag: playerArtHeroTag,
                    child: TrackArt(track: track, size: side, radius: 20),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist ?? l10n.unknownArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(ZemaRadius.medium),
              ),
              child: Center(
                child: Text(
                  l10n.playerNoLyrics,
                  style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
              ),
            ),
          ),
        ),
        SeekBar(duration: snapshot.duration ?? track.duration),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: _Controls(snapshot: snapshot),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _SecondaryActions(),
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.snapshot});

  final PlayerSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final player = ref.read(playerControllerProvider);
    final repeatOn = snapshot.repeat != QueueRepeat.off;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: snapshot.shuffle
              ? l10n.playerShuffleOn
              : l10n.playerShuffleOff,
          isSelected: snapshot.shuffle,
          icon: Icon(
            Icons.shuffle,
            color: snapshot.shuffle ? colors.primaryText : colors.muted,
          ),
          onPressed: () => unawaited(player.toggleShuffle()),
        ),
        IconButton(
          tooltip: l10n.playerPrevious,
          iconSize: 36,
          icon: Icon(Icons.skip_previous, color: colors.text),
          onPressed: () => unawaited(player.previous()),
        ),
        SizedBox.square(
          dimension: 68,
          child: IconButton.filled(
            tooltip: snapshot.playing ? l10n.playerPause : l10n.playerPlay,
            iconSize: 38,
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            icon: Icon(snapshot.playing ? Icons.pause : Icons.play_arrow),
            onPressed: () => unawaited(player.togglePlay()),
          ),
        ),
        IconButton(
          tooltip: l10n.playerNext,
          iconSize: 36,
          icon: Icon(Icons.skip_next, color: colors.text),
          onPressed: () => unawaited(player.next()),
        ),
        IconButton(
          tooltip: switch (snapshot.repeat) {
            QueueRepeat.off => l10n.playerRepeatOff,
            QueueRepeat.all => l10n.playerRepeatAll,
            QueueRepeat.one => l10n.playerRepeatOne,
          },
          isSelected: repeatOn,
          icon: Icon(
            snapshot.repeat == QueueRepeat.one
                ? Icons.repeat_one
                : Icons.repeat,
            color: repeatOn ? colors.primaryText : colors.muted,
          ),
          onPressed: () => unawaited(player.cycleRepeat()),
        ),
      ],
    );
  }
}

/// Sleep timer (with the time left when one runs) and queue.
class _SecondaryActions extends ConsumerWidget {
  const _SecondaryActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final timer = ref.watch(sleepTimerProvider);
    final color = timer == null ? colors.muted : colors.primaryText;
    final label = switch (timer) {
      null => null,
      final TimedSleep timed => SleepCountdown(
        timer: timed,
        builder: (context, left) => Text(formatDuration(left)),
      ),
      EndOfTrackSleep() => Text(l10n.sleepEndOfSongShort),
    };
    return Row(
      children: [
        Tooltip(
          message: l10n.sleepTitle,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: color,
              minimumSize: const Size(ZemaSpacing.minTap, ZemaSpacing.minTap),
            ),
            onPressed: () => unawaited(showSleepTimerSheet(context)),
            icon: Icon(timer == null ? Icons.bedtime_outlined : Icons.bedtime),
            label: label ?? const SizedBox.shrink(),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: l10n.queueTitle,
          icon: Icon(Icons.queue_music, color: colors.muted),
          onPressed: () => unawaited(showQueueSheet(context)),
        ),
      ],
    );
  }
}
