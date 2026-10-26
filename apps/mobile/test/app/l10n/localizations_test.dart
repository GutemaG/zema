import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppLocalizations', () {
    test('supports en, am, om and ti', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        unorderedEquals(['en', 'am', 'om', 'ti']),
      );
    });

    test('translated languages fall back to English for missing keys', () {
      final en = lookupAppLocalizations(const Locale('en'));
      for (final code in ['am', 'om', 'ti']) {
        final l10n = lookupAppLocalizations(Locale(code));
        expect(l10n.navHome, isNot(en.navHome), reason: code);
        expect(l10n.errorNotFoundTitle, en.errorNotFoundTitle, reason: code);
      }
    });
  });

  group('first-launch language', () {
    testWidgets('UI is Amharic when the device is set to am', (tester) async {
      await pumpZemaApp(tester, deviceLocales: const [Locale('am', 'ET')]);

      expect(find.text('ዋና ገጽ'), findsOneWidget);
      expect(find.text('ፍለጋ'), findsOneWidget);
      // Not translated yet, so English.
      expect(find.byTooltip('Search'), findsOneWidget);
    });

    testWidgets('UI is English when the device is set to fr', (tester) async {
      await pumpZemaApp(tester, deviceLocales: const [Locale('fr')]);

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('saved language wins over the device locale', (tester) async {
      await pumpZemaApp(
        tester,
        deviceLocales: const [Locale('am')],
        savedLanguage: 'ti',
      );

      expect(find.text('መበገሲ'), findsOneWidget);
      expect(find.text('ዋና ገጽ'), findsNothing);
    });
  });

  // Flutter has no built-in Material/Cupertino/Widgets strings for om or ti;
  // the fallback delegates must supply English ones.
  for (final code in ['om', 'ti']) {
    group('built-in strings for $code', () {
      testWidgets('Material widgets render English strings', (tester) async {
        await pumpZemaApp(tester, deviceLocales: [Locale(code)]);
        // Open Settings from Home so its app bar has a back button.
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(AppBar));
        expect(Localizations.localeOf(context).languageCode, code);
        expect(MaterialLocalizations.of(context).backButtonTooltip, 'Back');
        expect(find.byTooltip('Back'), findsOneWidget);
      });

      testWidgets('dialogs open without crashing', (tester) async {
        await pumpZemaApp(tester, deviceLocales: [Locale(code)]);

        final context = tester.element(find.byType(Scaffold).first);
        showAboutDialog(context: context, applicationName: 'Zema');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('View licenses'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      });
    });
  }
}
