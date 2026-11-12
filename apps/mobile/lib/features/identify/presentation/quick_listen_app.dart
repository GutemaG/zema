import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/fallback_localizations.dart';
import '../../../app/l10n/language_providers.dart';
import '../../../app/theme/palette_provider.dart';
import '../../../app/theme/zema_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_bootstrap.dart';
import '../application/quick_listen.dart';
import '../data/quick_launch.dart';
import 'listen_screen.dart';

Future<void> runQuickListen() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsOverrides = await loadSettingsOverrides();
  runApp(
    ProviderScope(
      overrides: [
        ...settingsOverrides,
        quickListenHostProvider.overrideWithValue(
          const AndroidQuickListenHost(),
        ),
      ],
      child: const QuickListenApp(),
    ),
  );
}

class QuickListenApp extends ConsumerWidget {
  const QuickListenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeWidgetSyncProvider, (_, _) {});
    final palette = ref.watch(paletteProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).listenTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette, Brightness.light),
      darkTheme: buildTheme(palette, Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      home: const ListenScreen(),
    );
  }
}
