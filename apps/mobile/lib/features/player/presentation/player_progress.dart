import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../application/player_providers.dart';

/// The fill color for thin progress indicators: gold in dark mode; in light
/// mode gold on cream is too faint (≈ 1.9:1), so `accent` is used.
Color progressColor(BuildContext context) {
  final colors = context.zemaColors;
  return Theme.of(context).brightness == Brightness.dark
      ? colors.primary
      : colors.accent;
}

/// A 2 px progress line for the mini player. Decorative: the controls carry
/// the meaning for screen readers.
class PlayerProgressLine extends ConsumerWidget {
  const PlayerProgressLine({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = duration.inMilliseconds;
    final value = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: LinearProgressIndicator(
        value: value,
        minHeight: 2,
        color: progressColor(context),
        backgroundColor: context.zemaColors.line,
      ),
    );
  }
}

/// The Now Playing seek bar with elapsed and remaining time. While dragging,
/// the time follows the thumb; audio seeks when it's released.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, required this.duration});

  final Duration duration;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  /// Thumb position while dragging, in milliseconds.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final max = widget.duration.inMilliseconds.toDouble();
    final playing =
        ref.watch(positionProvider).value?.inMilliseconds.toDouble() ?? 0;
    final value = (_dragging ?? playing).clamp(0.0, max <= 0 ? 0.0 : max);
    final shown = Duration(milliseconds: value.round());
    final remaining = widget.duration - shown;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // One screen-reader node: "Song position, 1:05 of 3:40".
        MergeSemantics(
          child: Semantics(
            label: l10n.playerSeek,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: progressColor(context),
                inactiveTrackColor: colors.line,
                thumbColor: progressColor(context),
                overlayColor: progressColor(context).withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                max: max <= 0 ? 1 : max,
                // Read out as "1:05 of 3:40" instead of a percentage.
                semanticFormatterCallback: (v) => l10n.playerTrackPosition(
                  formatDuration(Duration(milliseconds: v.round())),
                  formatDuration(widget.duration),
                ),
                onChanged: max <= 0
                    ? null
                    : (v) => setState(() => _dragging = v),
                onChangeEnd: max <= 0
                    ? null
                    : (v) {
                        setState(() => _dragging = null);
                        ref
                            .read(playerControllerProvider)
                            .seek(Duration(milliseconds: v.round()));
                      },
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(shown),
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                Text(
                  '-${formatDuration(remaining)}',
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
