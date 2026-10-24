import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_language.dart';
import '../../../../app/l10n/language_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_controller.dart';

/// Opens the Language picker. Picking a language applies and saves it, then
/// closes the sheet; picking the active language only closes it.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LanguagePicker(),
  );
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(appLanguageProvider);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.settingsLanguage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RadioGroup<AppLanguage>(
              groupValue: current,
              onChanged: (language) {
                Navigator.of(context).pop();
                if (language != null && language != current) {
                  ref
                      .read(settingsProvider.notifier)
                      .setLanguage(language.code);
                }
              },
              child: Column(
                children: [
                  for (final language in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: language,
                      // Tapping the selected option reports null, so it still
                      // closes the sheet.
                      toggleable: true,
                      // Always in its own script, never translated.
                      title: Text(language.nativeName, locale: language.locale),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
