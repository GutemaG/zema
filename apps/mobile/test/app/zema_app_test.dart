import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/l10n/language_providers.dart';
import 'package:zema/app/theme/palette_provider.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/zema_app.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  ZemaPalette palette = ZemaPalette.fallback,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceLocalesProvider.overrideWithValue(const [Locale('en')]),
        paletteProvider.overrideWithValue(palette),
      ],
      child: const ZemaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ZemaApp', () {
    testWidgets('starts on Home inside a ProviderScope', (tester) async {
      await _pumpApp(tester);

      expect(find.byType(ProviderScope), findsOneWidget);
      expect(find.byType(ZemaApp), findsOneWidget);
      expect(find.text('Zema'), findsOneWidget);
    });

    testWidgets('uses Night Vigil by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceLocalesProvider.overrideWithValue(const [Locale('en')]),
          ],
          child: const ZemaApp(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Zema'));
      expect(context.zemaColors, ZemaColors.nightVigil);
    });

    testWidgets('uses the palette from paletteProvider', (tester) async {
      await _pumpApp(tester, palette: ZemaPalette.wine);

      final context = tester.element(find.text('Zema'));
      expect(context.zemaColors, ZemaColors.wine);
    });
  });
}
