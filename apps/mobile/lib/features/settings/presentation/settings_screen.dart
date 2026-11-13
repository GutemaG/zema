import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/language_providers.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/account_providers.dart';
import '../../account/presentation/widgets/sign_in_prompt.dart';
import '../../library/application/library_access_controller.dart';
import '../../library/application/library_providers.dart';
import '../../library/application/library_sync_controller.dart';
import '../../lyrics/presentation/lyrics_settings_group.dart';
import '../application/app_version_provider.dart';
import '../application/settings_controller.dart';
import '../data/app_settings.dart';
import 'widgets/appearance_picker.dart';
import 'widgets/choice_picker.dart';
import 'widgets/language_picker.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_row.dart';

/// Shown when the version can't be read.
const String _unavailable = '—';

/// S28: General (Language, Appearance), Account (Account & backup, when
/// sign-in is available), Library (hidden folders and songs,
/// rescan, minimum length), Playback (sleep timer default, unplug,
/// interruptions, gapless) and About (Version, licenses). Later intents add
/// their own sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Scans again and reports how many songs the library shows. Without
  /// access, opens the Library tab, where the permission flow runs.
  Future<void> _rescan(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    if (ref.read(libraryAccessProvider).value != LibraryAccess.granted) {
      context.go(AppRoutes.library);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final sync = ref.read(librarySyncProvider.notifier);
    final library = ref.read(libraryRepositoryProvider);
    final minDuration = ref.read(minTrackDurationProvider);
    await sync.sync();
    if (!context.mounted) return;
    final SnackBar snack;
    if (ref.read(librarySyncProvider).hasFailed) {
      snack = SnackBar(
        content: Text(l10n.libraryScanFailedSnack),
        action: SnackBarAction(
          label: l10n.actionTryAgain,
          onPressed: () => unawaited(_rescan(context, ref)),
        ),
      );
    } else {
      final count = await library.countTracks(minDuration: minDuration);
      snack = SnackBar(content: Text(l10n.settingsRescanDone(count)));
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  /// S25b when signed in; for a guest, the sign-in sheet (C09), which
  /// returns here. Waits for the saved session if it is still being
  /// restored.
  Future<void> _openBackup(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(authUserProvider.future);
    if (!context.mounted) return;
    if (user != null) {
      await context.push<void>(AppRoutes.backup);
      return;
    }
    await showSignInPrompt(
      context,
      reason: AppLocalizations.of(context).backupSignInReason,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signInAvailable = ref.watch(signInAvailableProvider);
    // Restores the session, so Account & backup knows who is signed in.
    if (signInAvailable) ref.watch(authUserProvider);
    final language = ref.watch(appLanguageProvider);
    final version = ref.watch(appVersionProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final scanning = ref.watch(librarySyncProvider.select((s) => s.isScanning));
    final hiddenFolders = ref.watch(hiddenFoldersProvider).value?.length;
    final hiddenSongs = ref.watch(hiddenTracksProvider).value?.length;

    String seconds(int value) =>
        value == 0 ? l10n.settingsOff : l10n.settingsSeconds(value);
    String sleepDefault(SleepTimerDefault value) => switch (value) {
      SleepTimerDefault.none => l10n.settingsNone,
      SleepTimerDefault.endOfSong => l10n.sleepEndOfSong,
      _ => l10n.sleepMinutes(value.minutes!),
    };
    String interruptions(bool duck) =>
        duck ? l10n.settingsInterruptionsDuck : l10n.settingsInterruptionsPause;
    Widget toggle(bool value, Future<void> Function(bool) onChanged) =>
        Switch(value: value, onChanged: (v) => unawaited(onChanged(v)));

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
                value: localizedAppearance(
                  l10n,
                  settings.palette,
                  settings.themeMode,
                ),
                onTap: () => showAppearancePicker(context),
              ),
            ],
          ),
          if (signInAvailable)
            SettingsGroup(
              title: l10n.settingsSectionAccount,
              children: [
                SettingsRow(
                  label: l10n.settingsAccountBackup,
                  onTap: () => unawaited(_openBackup(context, ref)),
                ),
              ],
            ),
          SettingsGroup(
            title: l10n.settingsSectionLibrary,
            children: [
              SettingsRow(
                label: l10n.settingsHiddenFolders,
                value: hiddenFolders == null ? null : '$hiddenFolders',
                onTap: () => unawaited(context.push(AppRoutes.hiddenFolders)),
              ),
              SettingsRow(
                label: l10n.settingsHiddenSongs,
                value: hiddenSongs == null ? null : '$hiddenSongs',
                onTap: () => unawaited(context.push(AppRoutes.hiddenSongs)),
              ),
              SettingsRow(
                label: l10n.settingsRescan,
                value: scanning ? l10n.settingsRescanning : null,
                trailing: scanning
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: scanning ? null : () => unawaited(_rescan(context, ref)),
              ),
              SettingsRow(
                label: l10n.settingsMinDuration,
                value: seconds(settings.minTrackSeconds),
                onTap: () async {
                  final picked = await showChoicePicker<int>(
                    context,
                    title: l10n.settingsMinDuration,
                    options: [
                      for (final value in AppSettings.minTrackChoices)
                        (value, seconds(value)),
                    ],
                    current: settings.minTrackSeconds,
                  );
                  if (picked != null) {
                    await controller.setMinTrackSeconds(picked);
                  }
                },
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.settingsSectionPlayback,
            children: [
              SettingsRow(
                label: l10n.settingsSleepDefault,
                value: sleepDefault(settings.sleepTimerDefault),
                onTap: () async {
                  final picked = await showChoicePicker<SleepTimerDefault>(
                    context,
                    title: l10n.settingsSleepDefault,
                    options: [
                      for (final value in SleepTimerDefault.values)
                        (value, sleepDefault(value)),
                    ],
                    current: settings.sleepTimerDefault,
                  );
                  if (picked != null) {
                    await controller.setSleepTimerDefault(picked);
                  }
                },
              ),
              SettingsRow(
                label: l10n.settingsPauseOnUnplug,
                trailing: toggle(
                  settings.pauseOnUnplug,
                  controller.setPauseOnUnplug,
                ),
                onTap: () => unawaited(
                  controller.setPauseOnUnplug(!settings.pauseOnUnplug),
                ),
              ),
              SettingsRow(
                label: l10n.settingsInterruptions,
                value: interruptions(settings.duckOnInterruption),
                onTap: () async {
                  final picked = await showChoicePicker<bool>(
                    context,
                    title: l10n.settingsInterruptions,
                    options: [
                      (false, interruptions(false)),
                      (true, interruptions(true)),
                    ],
                    current: settings.duckOnInterruption,
                    note: l10n.settingsInterruptionsNote,
                  );
                  if (picked != null) {
                    await controller.setDuckOnInterruption(picked);
                  }
                },
              ),
              SettingsRow(
                label: l10n.settingsGapless,
                trailing: toggle(settings.gapless, controller.setGapless),
                onTap: () =>
                    unawaited(controller.setGapless(!settings.gapless)),
              ),
            ],
          ),
          const LyricsSettingsGroup(),
          if (Platform.isAndroid)
            SettingsGroup(
              title: l10n.settingsSectionOtherApps,
              children: [
                SettingsRow(
                  label: l10n.detectionSettingsTitle,
                  onTap: () =>
                      unawaited(context.push(AppRoutes.detectionSettings)),
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
