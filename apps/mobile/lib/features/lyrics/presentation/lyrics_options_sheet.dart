import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/lyrics_prefs.dart';
import '../application/track_lyrics.dart';

/// Opens the lyrics options: transliteration, text size and, for synced
/// lyrics, the sync offset of their recording.
Future<void> showLyricsOptionsSheet(BuildContext context, TrackLyrics lyrics) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => LyricsOptionsSheet(lyrics: lyrics),
  );
}

/// "+1.5 s", "−0.5 s", "0.0 s".
String formatOffset(Duration offset) {
  final seconds = (offset.inMilliseconds.abs() / 1000).toStringAsFixed(1);
  final sign = offset.isNegative
      ? '−'
      : offset > Duration.zero
      ? '+'
      : '';
  return '$sign$seconds s';
}

class LyricsOptionsSheet extends ConsumerWidget {
  const LyricsOptionsSheet({super.key, required this.lyrics});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final display = ref.watch(lyricsDisplayProvider);
    final displayController = ref.read(lyricsDisplayProvider.notifier);
    final recording = lyrics.recording;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                0,
                ZemaSpacing.screenSide,
                8,
              ),
              child: Text(
                l10n.lyricsOptions,
                style: textTheme.titleMedium?.copyWith(color: colors.text),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.lyricsShowTransliteration),
              value: display.showTransliteration,
              onChanged: (show) =>
                  unawaited(displayController.setTransliteration(show: show)),
            ),
            LyricsStepper(
              label: l10n.lyricsTextSize,
              value: '${(display.textScale * 100).round()}%',
              lessTooltip: l10n.lyricsTextSmaller,
              lessIcon: Icons.text_decrease,
              onLess: display.canShrink
                  ? () => unawaited(displayController.stepScale(-1))
                  : null,
              moreTooltip: l10n.lyricsTextLarger,
              moreIcon: Icons.text_increase,
              onMore: display.canGrow
                  ? () => unawaited(displayController.stepScale(1))
                  : null,
            ),
            if (lyrics.synced != null && recording != null)
              Consumer(
                builder: (context, ref, _) {
                  final own = ref.watch(lyricsOffsetProvider(recording.id));
                  final offset =
                      own ?? ref.watch(lyricsDisplayProvider).defaultOffset;
                  final controller = ref.read(
                    lyricsOffsetProvider(recording.id).notifier,
                  );
                  const limit = LyricsOffsetController.limit;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LyricsStepper(
                        label: l10n.lyricsSyncOffset,
                        value: formatOffset(offset),
                        lessTooltip: l10n.lyricsOffsetEarlier,
                        lessIcon: Icons.remove,
                        onLess: offset > -limit
                            ? () => unawaited(controller.nudge(-1))
                            : null,
                        moreTooltip: l10n.lyricsOffsetLater,
                        moreIcon: Icons.add,
                        onMore: offset < limit
                            ? () => unawaited(controller.nudge(1))
                            : null,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ZemaSpacing.screenSide - 8,
                          ),
                          child: TextButton(
                            onPressed: own == null
                                ? null
                                : () => unawaited(controller.reset()),
                            child: Text(l10n.lyricsOffsetReset),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A labelled − value + row.
class LyricsStepper extends StatelessWidget {
  const LyricsStepper({
    super.key,
    required this.label,
    required this.value,
    required this.lessTooltip,
    required this.lessIcon,
    required this.onLess,
    required this.moreTooltip,
    required this.moreIcon,
    required this.onMore,
  });

  final String label;
  final String value;
  final String lessTooltip;
  final IconData lessIcon;
  final VoidCallback? onLess;
  final String moreTooltip;
  final IconData moreIcon;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ZemaSpacing.screenSide,
        4,
        ZemaSpacing.screenSide - 8,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: colors.text),
            ),
          ),
          IconButton(
            tooltip: lessTooltip,
            icon: Icon(lessIcon),
            onPressed: onLess,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: colors.text),
            ),
          ),
          IconButton(
            tooltip: moreTooltip,
            icon: Icon(moreIcon),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}
