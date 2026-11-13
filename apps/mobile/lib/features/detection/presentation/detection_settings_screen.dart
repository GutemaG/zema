import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../lyrics/presentation/lyrics_options_sheet.dart';
import '../../settings/presentation/widgets/choice_picker.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../../settings/presentation/widgets/settings_row.dart';
import '../application/detected_song.dart';
import '../application/detection_settings.dart';
import '../data/lyrics_overlay.dart';
import 'permissions_group.dart';

class DetectionSettingsScreen extends ConsumerStatefulWidget {
  const DetectionSettingsScreen({super.key});

  @override
  ConsumerState<DetectionSettingsScreen> createState() =>
      _DetectionSettingsScreenState();
}

class _DetectionSettingsScreenState
    extends ConsumerState<DetectionSettingsScreen> {
  Future<void> _clear(
    String title,
    String message,
    Future<void> Function() clear,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.detectionClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await clear();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.detectionCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final settings = ref.watch(detectionSettingsProvider).value;
    final controller = ref.read(detectionSettingsProvider.notifier);
    final enabled = settings?.enabled ?? false;
    final appearance = settings?.appearance ?? const OverlayAppearance();

    String showAs(OverlayStart start) => switch (start) {
      OverlayStart.bubble => l10n.detectionShowBubble,
      OverlayStart.bar => l10n.detectionShowBar,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detectionSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZemaSpacing.screenSide,
          0,
          ZemaSpacing.screenSide,
          24,
        ),
        children: [
          const PermissionsGroup(),
          SettingsGroup(
            title: l10n.detectionSectionDetection,
            children: [
              SettingsRow(
                label: l10n.detectionEnabled,
                trailing: Switch(
                  value: enabled,
                  onChanged: settings == null
                      ? null
                      : (on) => unawaited(controller.setEnabled(on)),
                ),
                onTap: settings == null
                    ? null
                    : () => unawaited(controller.setEnabled(!enabled)),
              ),
              for (final app in DetectionApp.values)
                SettingsRow(
                  key: ValueKey(app),
                  label: app.label,
                  trailing: Switch(
                    value: settings?.watches(app) ?? false,
                    onChanged: enabled
                        ? (on) => unawaited(controller.setApp(app, on))
                        : null,
                  ),
                  onTap: enabled
                      ? () => unawaited(
                          controller.setApp(app, !settings!.watches(app)),
                        )
                      : null,
                ),
              SettingsRow(
                label: l10n.detectionShowAs,
                value: showAs(appearance.start),
                onTap: settings == null
                    ? null
                    : () async {
                        final picked = await showChoicePicker<OverlayStart>(
                          context,
                          title: l10n.detectionShowAs,
                          options: [
                            for (final start in OverlayStart.values)
                              (start, showAs(start)),
                          ],
                          current: appearance.start,
                        );
                        if (picked != null) {
                          await controller.setAppearance(
                            appearance.copyWith(start: picked),
                          );
                        }
                      },
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.detectionSectionAppearance,
            children: [
              _Preview(appearance: appearance),
              LyricsStepper(
                label: l10n.lyricsTextSize,
                value: '${appearance.textSize.round()}',
                lessTooltip: l10n.lyricsTextSmaller,
                lessIcon: Icons.text_decrease,
                onLess:
                    settings != null &&
                        appearance.textSize > OverlayAppearance.minText
                    ? () => unawaited(
                        controller.setAppearance(
                          appearance.copyWith(
                            textSize: appearance.textSize - 2,
                          ),
                        ),
                      )
                    : null,
                moreTooltip: l10n.lyricsTextLarger,
                moreIcon: Icons.text_increase,
                onMore:
                    settings != null &&
                        appearance.textSize < OverlayAppearance.maxText
                    ? () => unawaited(
                        controller.setAppearance(
                          appearance.copyWith(
                            textSize: appearance.textSize + 2,
                          ),
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.detectionOpacity,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Expanded(
                      child: Slider(
                        value: appearance.opacity,
                        min: OverlayAppearance.minOpacity,
                        divisions: 6,
                        onChanged: settings == null
                            ? null
                            : (value) => unawaited(
                                controller.setAppearance(
                                  appearance.copyWith(opacity: value),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.detectionSectionMatching,
            children: [
              SettingsRow(
                label: l10n.detectionClearMatches,
                onTap: () => unawaited(
                  _clear(
                    l10n.detectionClearMatchesTitle,
                    l10n.detectionClearMatchesMessage,
                    ref.read(detectedMatchControllerProvider).clearAll,
                  ),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.detectionSectionIdentification,
            children: [
              SettingsRow(
                label: l10n.detectionClearListenHistory,
                onTap: () => unawaited(
                  _clear(
                    l10n.detectionClearListenHistoryTitle,
                    l10n.detectionClearListenHistoryMessage,
                    ref.read(databaseProvider).identifiedDao.clear,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              16,
              ZemaSpacing.screenSide,
              0,
            ),
            child: Text(
              l10n.detectionPrivacy,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.appearance});

  final OverlayAppearance appearance;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: ZemaSpacing.screenSide,
      vertical: 8,
    ),
    child: Opacity(
      opacity: appearance.opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: OverlayColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).detectionPreviewLine,
              style: TextStyle(
                color: OverlayColors.text,
                fontSize: appearance.textSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).detectionPreviewNext,
              style: TextStyle(
                color: OverlayColors.muted,
                fontSize: appearance.textSize * 0.8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
