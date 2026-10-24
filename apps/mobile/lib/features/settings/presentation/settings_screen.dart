import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/language_providers.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/app_version_provider.dart';
import '../application/settings_controller.dart';
import 'widgets/appearance_picker.dart';
import 'widgets/language_picker.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_row.dart';

/// Shown when the version can't be read.
const String _unavailable = '—';

/// S28, minimal: General (Language, Appearance) and About (Version,
/// licenses). Later intents add their own sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = ref.watch(settingsProvider.select((s) => s.palette));
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final language = ref.watch(appLanguageProvider);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZemaSpacing.screenSide,
          0,
          ZemaSpacing.screenSide,
          24,
        ),
        children: [
          SettingsGroup(
            title: l10n.settingsSectionGeneral,
            children: [
              SettingsRow(
                label: l10n.settingsLanguage,
                value: language.nativeName,
                onTap: () => showLanguagePicker(context),
              ),
              SettingsRow(
                label: l10n.settingsAppearance,
                value: localizedAppearance(l10n, palette, themeMode),
                onTap: () => showAppearancePicker(context),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionAbout,
            children: [
              SettingsRow(
                label: l10n.settingsVersion,
                value: version.when(
                  data: (value) => value,
                  loading: () => '',
                  error: (_, _) => _unavailable,
                ),
              ),
              SettingsRow(
                label: l10n.settingsLicenses,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: version.value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
