import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/l10n/language_providers.dart';
import 'package:zema/app/router.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/theme/zema_theme.dart';
import 'package:zema/app/zema_app.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

/// Pumps the full app with a fake device locale list and a fresh router
/// starting at [location].
Future<void> pumpZemaApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  List<Locale> deviceLocales = const [Locale('en')],
  String? savedLanguage,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceLocalesProvider.overrideWithValue(deviceLocales),
        savedLanguageCodeProvider.overrideWithValue(savedLanguage),
        routerProvider.overrideWith((ref) {
          final router = buildRouter(initialLocation: location);
          ref.onDispose(router.dispose);
          return router;
        }),
      ],
      child: const ZemaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps [child] inside the app theme and English localizations, without the
/// router. For testing shared widgets on their own.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(ZemaPalette.fallback),
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
