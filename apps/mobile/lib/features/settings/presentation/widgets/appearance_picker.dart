import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_palette.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_controller.dart';

/// The palette's display name in the current UI language.
String localizedPaletteName(AppLocalizations l10n, ZemaPalette palette) {
  return switch (palette) {
    ZemaPalette.nightVigil => l10n.paletteNightVigil,
    ZemaPalette.wine => l10n.paletteWine,
  };
}

/// The theme mode's display name in the current UI language.
String localizedThemeModeName(AppLocalizations l10n, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => l10n.themeModeSystem,
    ThemeMode.light => l10n.themeModeLight,
    ThemeMode.dark => l10n.themeModeDark,
  };
}

/// Value shown on the Settings row, e.g. "Night Vigil · System".
String localizedAppearance(
  AppLocalizations l10n,
  ZemaPalette palette,
  ThemeMode mode,
) {
  return '${localizedPaletteName(l10n, palette)} · '
      '${localizedThemeModeName(l10n, mode)}';
}

/// Opens the Appearance sheet: a System / Light / Dark switch and one preview
/// card per palette. Every tap applies and saves immediately, and the sheet
/// stays open so combinations can be tried; Done closes it.
Future<void> showAppearancePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AppearancePicker(),
  );
}

class _AppearancePicker extends ConsumerWidget {
  const _AppearancePicker();

  static const _modeIcons = {
    ThemeMode.system: Icons.brightness_auto_outlined,
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    // The sheet re-themes along with the app, so this is the mode on screen.
    final brightness = Theme.of(context).brightness;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsAppearance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: [
                for (final mode in ThemeMode.values)
                  ButtonSegment(
                    value: mode,
                    icon: Icon(_modeIcons[mode]),
                    label: Text(
                      localizedThemeModeName(l10n, mode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {settings.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  controller.setThemeMode(selection.single),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final palette in ZemaPalette.values) ...[
                  if (palette != ZemaPalette.values.first)
                    const SizedBox(width: 12),
                  Expanded(
                    child: PalettePreviewCard(
                      label: localizedPaletteName(l10n, palette),
                      colors: palette.colorsFor(brightness),
                      selected: palette == settings.palette,
                      onTap: () => controller.setPalette(palette),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(ZemaSpacing.minTap),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.actionDone),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable miniature of a palette: background, a card with two text
/// lines and a gold button, drawn in that palette's colors.
class PalettePreviewCard extends StatelessWidget {
  const PalettePreviewCard({
    super.key,
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ZemaColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.zemaColors;
    final radius = BorderRadius.circular(ZemaRadius.medium);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? app.accent : app.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: _Miniature(colors: colors),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check_circle, size: 18, color: app.accentText),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: selected ? app.text : app.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Miniature extends StatelessWidget {
  const _Miniature({required this.colors});

  final ZemaColors colors;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, Color color) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.small - 4),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          bar(0.8, colors.text),
          bar(0.55, colors.muted),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              width: 28,
              height: 12,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
