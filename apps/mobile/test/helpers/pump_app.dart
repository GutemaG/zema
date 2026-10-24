import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/l10n/language_providers.dart';
import 'package:zema/app/router.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/theme/zema_theme.dart';
import 'package:zema/app/zema_app.dart';
import 'package:zema/features/settings/application/app_version_provider.dart';
import 'package:zema/features/settings/application/settings_bootstrap.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

/// Pumps the full app the way `main()` starts it: settings are loaded from
/// (mocked) saved preferences before the first frame.
///
/// [savedPrefs] are the stored values, e.g. `{'paletteId': 'wine'}`;
/// [savedLanguage] is shorthand for `{'localeCode': …}`. The device locale
/// list, the phone's light/dark setting ([phoneBrightness], dark by default
/// so the System theme renders the dark palettes), start route and app
/// version are faked. With [settle] false only the first frame is pumped.
Future<void> pumpZemaApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  List<Locale> deviceLocales = const [Locale('en')],
  Brightness phoneBrightness = Brightness.dark,
  String? savedLanguage,
  Map<String, Object> savedPrefs = const {},
  Future<String> Function()? appVersion,
  bool settle = true,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = phoneBrightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  SharedPreferences.setMockInitialValues({
    ...savedPrefs,
    'localeCode': ?savedLanguage,
  });
  final settingsOverrides = await loadSettingsOverrides();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...settingsOverrides,
        deviceLocalesProvider.overrideWithValue(deviceLocales),
        appVersionProvider.overrideWith(
          (ref) => appVersion?.call() ?? Future.value('1.0.0 (1)'),
        ),
        routerProvider.overrideWith((ref) {
          final router = buildRouter(initialLocation: location);
          ref.onDispose(router.dispose);
          return router;
        }),
      ],
      child: const ZemaApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

/// The saved preferences as the app left them.
Future<SharedPreferences> savedPreferences() => SharedPreferences.getInstance();

/// Pumps [child] inside the app theme and English localizations, without the
/// router. For testing shared widgets on their own.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(ZemaPalette.fallback, Brightness.dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sets a phone-sized screen and text scale for this test; both are reset
/// when the test ends.
void useScreen(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1,
}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
