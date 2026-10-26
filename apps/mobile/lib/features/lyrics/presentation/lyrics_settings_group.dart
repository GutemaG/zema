import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/lyrics_prefs.dart';
import 'lyrics_options_sheet.dart';

/// S28's Lyrics section: text size, show transliteration and the default
/// sync offset, shared with Now Playing and Song detail.
class LyricsSettingsGroup extends ConsumerWidget {
  const LyricsSettingsGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final display = ref.watch(lyricsDisplayProvider);
    final controller = ref.read(lyricsDisplayProvider.notifier);
    const limit = LyricsOffsetController.limit;
    final offset = display.defaultOffset;
    return SettingsGroup(
      title: l10n.settingsSectionLyrics,
      children: [
        LyricsStepper(
          label: l10n.lyricsTextSize,
          value: '${(display.textScale * 100).round()}%',
          lessTooltip: l10n.lyricsTextSmaller,
          lessIcon: Icons.text_decrease,
          onLess: display.canShrink
              ? () => unawaited(controller.stepScale(-1))
              : null,
          moreTooltip: l10n.lyricsTextLarger,
          moreIcon: Icons.text_increase,
          onMore: display.canGrow
              ? () => unawaited(controller.stepScale(1))
              : null,
        ),
        SettingsRow(
          label: l10n.lyricsShowTransliteration,
          trailing: Switch(
            value: display.showTransliteration,
            onChanged: (show) =>
                unawaited(controller.setTransliteration(show: show)),
          ),
          onTap: () => unawaited(
            controller.setTransliteration(show: !display.showTransliteration),
          ),
        ),
        LyricsStepper(
          label: l10n.settingsLyricsDefaultOffset,
          value: formatOffset(offset),
          lessTooltip: l10n.lyricsOffsetEarlier,
          lessIcon: Icons.remove,
          onLess: offset > -limit
              ? () => unawaited(controller.nudgeDefaultOffset(-1))
              : null,
          moreTooltip: l10n.lyricsOffsetLater,
          moreIcon: Icons.add,
          onMore: offset < limit
              ? () => unawaited(controller.nudgeDefaultOffset(1))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            0,
            ZemaSpacing.screenSide,
            12,
          ),
          child: Text(
            l10n.settingsLyricsDefaultOffsetNote,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}
