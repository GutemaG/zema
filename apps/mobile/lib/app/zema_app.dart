import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'l10n/fallback_localizations.dart';
import 'l10n/language_providers.dart';
import 'router.dart';
import 'theme/palette_provider.dart';
import 'theme/zema_theme.dart';

/// Root widget of the app. Must sit below a [ProviderScope].
class ZemaApp extends ConsumerWidget {
  const ZemaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(ref.watch(paletteProvider)),
      themeMode: ThemeMode.dark,
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
