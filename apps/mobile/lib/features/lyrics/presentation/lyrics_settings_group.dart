import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_bytes.dart';
import '../../catalog/application/lyrics_download.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/lyrics_prefs.dart';
import 'lyrics_options_sheet.dart';

/// S28's Lyrics section: text size, show transliteration and the default
/// sync offset, shared with Now Playing and Song detail; then the
/// downloaded lyrics, Download all and Clear.
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
        const _OfflineLyricsRows(),
      ],
    );
  }
}

/// Storage used, Download all (with progress and Cancel) and Clear.
class _OfflineLyricsRows extends ConsumerWidget {
  const _OfflineLyricsRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final usage = ref.watch(lyricsUsageProvider).value;
    final download = ref.watch(lyricsDownloaderProvider);
    final downloader = ref.read(lyricsDownloaderProvider.notifier);
    final available = ref.watch(catalogRepositoryProvider) != null;
    final LyricsDownload(:done, :total) = download;
    final status = switch (download.status) {
      _ when !available => l10n.settingsLyricsDownloadUnavailable,
      LyricsDownloadStatus.idle => null,
      LyricsDownloadStatus.running when total == 0 =>
        l10n.settingsLyricsDownloadChecking,
      LyricsDownloadStatus.running => l10n.settingsLyricsDownloadProgress(
        done,
        total,
      ),
      LyricsDownloadStatus.finished => l10n.settingsLyricsDownloadDone,
      LyricsDownloadStatus.cancelled => l10n.settingsLyricsDownloadCancelled(
        done,
        total,
      ),
      LyricsDownloadStatus.failed when download.failure is NetworkFailure =>
        l10n.settingsLyricsDownloadOffline(done, total),
      LyricsDownloadStatus.failed => l10n.settingsLyricsDownloadFailed(
        done,
        total,
      ),
    };
    final songs = usage?.songs ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          label: l10n.settingsLyricsDownloaded,
          value: usage == null
              ? null
              : songs == 0
              ? l10n.settingsLyricsDownloadedNone
              : l10n.settingsLyricsDownloadedValue(
                  songs,
                  formatBytes(usage.bytes),
                ),
        ),
        SettingsRow(
          label: l10n.settingsLyricsDownloadAll,
          onTap: available && !download.running
              ? () => unawaited(downloader.start())
              : null,
          trailing: download.running
              ? TextButton(
                  onPressed: downloader.cancel,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primaryText,
                    minimumSize: const Size(
                      ZemaSpacing.minTap,
                      ZemaSpacing.minTap,
                    ),
                  ),
                  child: Text(l10n.actionCancel),
                )
              : null,
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              0,
              ZemaSpacing.screenSide,
              8,
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          ),
        if (download.running)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              0,
              ZemaSpacing.screenSide,
              8,
            ),
            child: LinearProgressIndicator(
              value: total == 0 ? null : done / total,
            ),
          ),
        SettingsRow(
          label: l10n.settingsLyricsClear,
          onTap: songs > 0 && !download.running
              ? () => unawaited(_confirmClear(context, downloader))
              : null,
        ),
      ],
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    LyricsDownloader downloader,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLyricsClearTitle),
        content: Text(l10n.settingsLyricsClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsLyricsClearConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await downloader.clear();
  }
}
