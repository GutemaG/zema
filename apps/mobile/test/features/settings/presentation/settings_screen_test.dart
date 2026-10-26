import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/licenses.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/zema_nav_bar.dart';
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema/features/settings/presentation/settings_screen.dart';
import 'package:zema/features/settings/presentation/widgets/appearance_picker.dart';
import 'package:zema/features/settings/presentation/widgets/settings_group.dart';
import 'package:zema/features/settings/presentation/widgets/settings_row.dart';

import '../../../helpers/pump_app.dart';

/// Opens Settings the way a user does: the gear in the Home header.
Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

Finder _row(String label) => find.widgetWithText(SettingsRow, label);

String? _rowValue(WidgetTester tester, String label) =>
    tester.widget<SettingsRow>(_row(label)).value;

ZemaColors _colorsOf(WidgetTester tester, Finder finder) =>
    tester.element(finder).zemaColors;

/// A screen tall enough to build every Settings row.
void _tallScreen(WidgetTester tester, {double textScale = 1}) =>
    useScreen(tester, size: const Size(360, 2400), textScale: textScale);

void main() {
  group('Settings screen', () {
    testWidgets('shows General, Library, Playback and About in order', (
      tester,
    ) async {
      _tallScreen(tester);
      await pumpZemaApp(tester);
      await _openSettings(tester);

      expect(find.byType(SettingsScreen), findsOneWidget);
      final headings = ['GENERAL', 'LIBRARY', 'PLAYBACK', 'ABOUT'];
      final tops = [
        for (final heading in headings)
          tester.getTopLeft(find.text(heading)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.byType(SettingsGroup), findsNWidgets(4));
      expect(find.byType(SettingsRow), findsNWidgets(12));
      for (final label in [
        'Language',
        'Appearance',
        'Hidden folders',
        'Hidden songs',
        'Rescan library',
        'Ignore audio shorter than',
        'Sleep timer default',
        'Pause when headphones are unplugged',
        'When another app plays sound',
        'Gapless playback',
        'Version',
        'Open-source licenses',
      ]) {
        expect(_row(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('has no other S28 sections', (tester) async {
      _tallScreen(tester);
      await pumpZemaApp(tester);
      await _openSettings(tester);

      for (final section in [
        'LYRICS',
        'ACCOUNT',
        'PRIVACY',
        'FLOATING LYRICS',
      ]) {
        expect(find.text(section), findsNothing, reason: section);
      }
    });

    testWidgets('shows current values; tappable rows have ›', (tester) async {
      _tallScreen(tester);
      await pumpZemaApp(tester);
      await _openSettings(tester);

      expect(_rowValue(tester, 'Language'), 'English');
      expect(_rowValue(tester, 'Appearance'), 'Night Vigil · System');
      expect(_rowValue(tester, 'Version'), '1.0.0 (1)');
      Finder chevronIn(String label) => find.descendant(
        of: _row(label),
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(chevronIn('Language'), findsOneWidget);
      expect(chevronIn('Appearance'), findsOneWidget);
      expect(chevronIn('Open-source licenses'), findsOneWidget);
      expect(chevronIn('Version'), findsNothing);
    });

    testWidgets('shows the saved language in its own script', (tester) async {
      await pumpZemaApp(tester, savedLanguage: 'ti');
      await _openSettings(tester);

      // Row label falls back to the ti translation; value is the native name.
      expect(_rowValue(tester, 'ቋንቋ'), 'ትግርኛ');
    });

    testWidgets('version shows — when it cannot be read', (tester) async {
      _tallScreen(tester);
      await pumpZemaApp(
        tester,
        appVersion: () => Future.error(Exception('no platform')),
      );
      await _openSettings(tester);

      expect(_rowValue(tester, 'Version'), '—');
    });

    testWidgets('licenses row opens the license page with both fonts', (
      tester,
    ) async {
      LicenseRegistry.reset();
      addTearDown(LicenseRegistry.reset);
      registerFontLicenses();
      _tallScreen(tester);
      await pumpZemaApp(tester);
      await _openSettings(tester);

      await tester.tap(_row('Open-source licenses'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Inter'), findsOneWidget);
      expect(find.text('Noto Sans Ethiopic'), findsOneWidget);
    });

    testWidgets('rows are labeled for screen readers and ≥ 44 px tall', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      _tallScreen(tester);
      await pumpZemaApp(tester);
      await _openSettings(tester);

      expect(
        tester.getSemantics(_row('Language')),
        isSemantics(label: 'Language\nEnglish', isButton: true),
      );
      expect(
        tester.getSemantics(_row('Version')),
        isSemantics(label: 'Version\n1.0.0 (1)', isButton: false),
      );
      for (final row in tester.widgetList<SettingsRow>(
        find.byType(SettingsRow),
      )) {
        expect(
          tester.getSize(find.byWidget(row)).height,
          greaterThanOrEqualTo(44),
          reason: row.label,
        );
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('no overflow at 1.3× on 360 dp in every language', (
      tester,
    ) async {
      _tallScreen(tester, textScale: 1.3);
      for (final code in ['en', 'am', 'om', 'ti']) {
        // Tear down the previous app so each language starts fresh on Home.
        await tester.pumpWidget(const SizedBox());
        await pumpZemaApp(tester, savedLanguage: code);
        await _openSettings(tester);
        expect(tester.takeException(), isNull, reason: code);
      }
    });
  });

  group('Appearance sheet', () {
    Future<void> openAppearance(WidgetTester tester) async {
      await tester.tap(_row('Appearance'));
      await tester.pumpAndSettle();
    }

    Finder card(String label) => find.widgetWithText(PalettePreviewCard, label);

    Finder segment(String label) => find.descendant(
      of: find.byType(SegmentedButton<ThemeMode>),
      matching: find.text(label),
    );

    testWidgets('shows the mode switch, two palette cards and Done', (
      tester,
    ) async {
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await openAppearance(tester);

      for (final mode in ['System', 'Light', 'Dark']) {
        expect(segment(mode), findsOneWidget, reason: mode);
      }
      expect(
        tester
            .widget<SegmentedButton<ThemeMode>>(
              find.byType(SegmentedButton<ThemeMode>),
            )
            .selected,
        {ThemeMode.system},
      );
      expect(find.byType(PalettePreviewCard), findsNWidgets(2));
      expect(
        tester.widget<PalettePreviewCard>(card('Night Vigil')).selected,
        isTrue,
      );
      expect(tester.widget<PalettePreviewCard>(card('Wine')).selected, isFalse);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('picking Wine re-themes at once, saves, and keeps the sheet', (
      tester,
    ) async {
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await openAppearance(tester);

      await tester.tap(card('Wine'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_colorsOf(tester, find.byType(SettingsScreen)), ZemaColors.wine);
      expect(tester.widget<PalettePreviewCard>(card('Wine')).selected, isTrue);
      expect((await savedPreferences()).getString('paletteId'), 'wine');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_rowValue(tester, 'Appearance'), 'Wine · System');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(_colorsOf(tester, find.byType(HomeScreen)), ZemaColors.wine);
      expect(_colorsOf(tester, find.byType(ZemaNavBar)), ZemaColors.wine);
    });

    testWidgets('Light switches a dark phone to light at once and saves', (
      tester,
    ) async {
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await openAppearance(tester);

      await tester.tap(segment('Light'));
      await tester.pumpAndSettle();

      expect(
        _colorsOf(tester, find.byType(SettingsScreen)),
        ZemaColors.nightVigilLight,
      );
      expect((await savedPreferences()).getString('themeMode'), 'light');
      // Preview cards follow the mode on screen.
      expect(
        tester.widget<PalettePreviewCard>(card('Wine')).colors,
        ZemaColors.wineLight,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(_rowValue(tester, 'Appearance'), 'Night Vigil · Light');
    });

    testWidgets('Dark keeps the app dark on a light phone', (tester) async {
      await pumpZemaApp(tester, phoneBrightness: Brightness.light);
      await _openSettings(tester);
      expect(
        _colorsOf(tester, find.byType(SettingsScreen)),
        ZemaColors.nightVigilLight,
      );
      await openAppearance(tester);

      await tester.tap(segment('Dark'));
      await tester.pumpAndSettle();

      expect(
        _colorsOf(tester, find.byType(SettingsScreen)),
        ZemaColors.nightVigil,
      );
      expect((await savedPreferences()).getString('themeMode'), 'dark');
    });

    testWidgets('System follows the phone switching light and dark live', (
      tester,
    ) async {
      await pumpZemaApp(tester, phoneBrightness: Brightness.light);
      expect(
        _colorsOf(tester, find.byType(HomeScreen)),
        ZemaColors.nightVigilLight,
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(_colorsOf(tester, find.byType(HomeScreen)), ZemaColors.nightVigil);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        _colorsOf(tester, find.byType(HomeScreen)),
        ZemaColors.nightVigilLight,
      );
    });

    testWidgets('palette cards are selectable buttons for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await openAppearance(tester);

      expect(
        tester.getSemantics(card('Night Vigil')),
        isSemantics(
          label: 'Night Vigil',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(card('Wine')),
        isSemantics(label: 'Wine', isButton: true, isSelected: false),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(44),
      );
      semantics.dispose();
    });

    testWidgets('fits at 1.3× on 360 dp in every language', (tester) async {
      useScreen(tester, textScale: 1.3);
      for (final code in ['en', 'am', 'om', 'ti']) {
        await tester.pumpWidget(const SizedBox());
        await pumpZemaApp(tester, savedLanguage: code);
        await _openSettings(tester);
        await tester.tap(find.byType(SettingsRow).at(1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: code);
      }
    });
  });

  group('Language picker', () {
    testWidgets('lists the four languages in their own scripts', (
      tester,
    ) async {
      await pumpZemaApp(tester);
      await _openSettings(tester);

      await tester.tap(_row('Language'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      for (final name in ['English', 'አማርኛ', 'Afaan Oromoo', 'ትግርኛ']) {
        expect(
          find.descendant(of: sheet, matching: find.text(name)),
          findsOneWidget,
          reason: name,
        );
      }
      final group = tester.widget<RadioGroup<Object?>>(
        find.byWidgetPredicate((w) => w is RadioGroup),
      );
      expect(group.groupValue.toString(), contains('en'));
    });

    testWidgets('picking አማርኛ switches strings immediately and is saved', (
      tester,
    ) async {
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await tester.tap(_row('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('አማርኛ'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('ቅንብሮች'), findsOneWidget);
      expect(_rowValue(tester, 'ቋንቋ'), 'አማርኛ');
      expect((await savedPreferences()).getString('localeCode'), 'am');

      // The back tooltip is in Amharic now, so find the button by type.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('ዋና ገጽ'), findsOneWidget);
    });

    testWidgets('picking the active language only closes the sheet', (
      tester,
    ) async {
      // Active language comes from the device; nothing saved yet.
      await pumpZemaApp(tester, deviceLocales: const [Locale('am')]);
      await _openSettings(tester);
      await tester.tap(_row('ቋንቋ'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('አማርኛ'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect((await savedPreferences()).getString('localeCode'), isNull);
    });

    testWidgets('Ethiopic options fit at 1.3× with line height ≥ 1.4', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      await pumpZemaApp(tester);
      await _openSettings(tester);
      await tester.tap(_row('Language'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final name in ['አማርኛ', 'ትግርኛ']) {
        final text = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(name),
        );
        final style = DefaultTextStyle.of(tester.element(text)).style
            .merge(tester.widget<Text>(text).style);
        expect(style.height, greaterThanOrEqualTo(1.4), reason: name);
      }
    });
  });

  group('saved settings on launch', () {
    testWidgets('first frame uses the saved palette and language', (
      tester,
    ) async {
      await pumpZemaApp(
        tester,
        deviceLocales: const [Locale('fr')],
        savedPrefs: const {
          'paletteId': 'wine',
          'themeMode': 'light',
          'localeCode': 'am',
        },
        settle: false,
      );

      // Only the first frame has been pumped.
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
      expect(app.theme?.extension<ZemaColors>(), ZemaColors.wineLight);
      expect(app.darkTheme?.extension<ZemaColors>(), ZemaColors.wine);
      expect(app.locale, const Locale('am'));
    });

    testWidgets('unknown saved values fall back without crashing', (
      tester,
    ) async {
      await pumpZemaApp(
        tester,
        savedPrefs: const {
          'paletteId': 'purple',
          'themeMode': 'sepia',
          'localeCode': 'xx',
        },
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(_colorsOf(tester, find.byType(HomeScreen)), ZemaColors.nightVigil);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
