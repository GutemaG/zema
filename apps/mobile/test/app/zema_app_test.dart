import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/zema_app.dart';

void main() {
  group('ZemaApp', () {
    testWidgets('starts and shows the app name', (tester) async {
      await tester.pumpWidget(const ZemaApp());

      expect(find.byType(ZemaApp), findsOneWidget);
      expect(find.text('Zema'), findsOneWidget);
      expect(find.text('ዜማ'), findsOneWidget);
    });

    testWidgets('uses Night Vigil when no palette is given', (tester) async {
      await tester.pumpWidget(const ZemaApp());

      final context = tester.element(find.text('Zema'));
      expect(Theme.of(context).extension<ZemaColors>(), ZemaColors.nightVigil);
    });

    testWidgets('uses the given palette', (tester) async {
      await tester.pumpWidget(const ZemaApp(palette: ZemaPalette.wine));

      final context = tester.element(find.text('Zema'));
      expect(context.zemaColors, ZemaColors.wine);
    });
  });
}
