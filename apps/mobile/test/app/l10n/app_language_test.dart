import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/l10n/app_language.dart';

void main() {
  group('resolveInitialLanguage', () {
    test('uses the saved language when it is valid', () {
      final language = resolveInitialLanguage(
        saved: 'ti',
        deviceLocales: const [Locale('am')],
      );
      expect(language, AppLanguage.ti);
    });

    test('ignores an unknown saved code and uses the device locale', () {
      final language = resolveInitialLanguage(
        saved: 'xx',
        deviceLocales: const [Locale('am')],
      );
      expect(language, AppLanguage.am);
    });

    test('uses Amharic when the device is set to am', () {
      final language = resolveInitialLanguage(
        saved: null,
        deviceLocales: const [Locale('am')],
      );
      expect(language, AppLanguage.am);
    });

    test('ignores the region when the device is set to am_ET', () {
      final language = resolveInitialLanguage(
        saved: null,
        deviceLocales: const [Locale('am', 'ET')],
      );
      expect(language, AppLanguage.am);
    });

    test('uses Afaan Oromoo and Tigrinya device locales', () {
      expect(
        resolveInitialLanguage(
          saved: null,
          deviceLocales: const [Locale('om')],
        ),
        AppLanguage.om,
      );
      expect(
        resolveInitialLanguage(
          saved: null,
          deviceLocales: const [Locale('ti', 'ER')],
        ),
        AppLanguage.ti,
      );
    });

    test('falls back to English when the device language is unsupported', () {
      final language = resolveInitialLanguage(
        saved: null,
        deviceLocales: const [Locale('fr')],
      );
      expect(language, AppLanguage.en);
    });

    test('uses the first supported device locale in order', () {
      expect(
        resolveInitialLanguage(
          saved: null,
          deviceLocales: const [Locale('en', 'US'), Locale('am')],
        ),
        AppLanguage.en,
      );
      expect(
        resolveInitialLanguage(
          saved: null,
          deviceLocales: const [Locale('fr'), Locale('om'), Locale('en')],
        ),
        AppLanguage.om,
      );
    });

    test('falls back to English when the device reports no locales', () {
      expect(
        resolveInitialLanguage(saved: null, deviceLocales: const []),
        AppLanguage.en,
      );
    });
  });

  group('AppLanguage', () {
    test('fromCode returns null for unknown and missing codes', () {
      expect(AppLanguage.fromCode('am'), AppLanguage.am);
      expect(AppLanguage.fromCode('xx'), isNull);
      expect(AppLanguage.fromCode(null), isNull);
    });

    test('each language has its locale and native name', () {
      expect(AppLanguage.am.locale, const Locale('am'));
      expect(AppLanguage.values.map((l) => l.nativeName), [
        'English',
        'አማርኛ',
        'Afaan Oromoo',
        'ትግርኛ',
      ]);
    });
  });
}
