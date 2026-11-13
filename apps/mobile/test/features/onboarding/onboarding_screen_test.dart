import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/l10n/app_language.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/application/detection_settings.dart';
import 'package:zema/features/onboarding/presentation/onboarding_screen.dart';

import '../../helpers/pump_app.dart';

class _Microphone implements MicrophoneAccess {
  var allowed = false;

  @override
  Future<bool> granted() async => allowed;

  @override
  Future<void> fix() async => allowed = true;
}

void main() {
  testWidgets('first launch: language, steps, permissions, then Home', (
    tester,
  ) async {
    useScreen(tester, size: const Size(400, 1000));
    final microphone = _Microphone();
    await pumpZemaApp(
      tester,
      savedPrefs: {'onboardingDone': false},
      overrides: [
        otherAppsSupportedProvider.overrideWithValue(true),
        microphoneAccessProvider.overrideWithValue(microphone),
      ],
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Zema'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey(AppLanguage.am)));
    await tester.pumpAndSettle();
    expect((await savedPreferences()).getString('localeCode'), 'am');
    await tester.tap(find.byKey(const ValueKey(AppLanguage.en)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);
    expect(
      find.text(
        'Playing a mezmur on YouTube or Telegram? Zema floats its lyrics on top',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Allow access'), findsOneWidget);
    expect(find.text('Music files'), findsOneWidget);
    expect(find.text('Fix'), findsNWidgets(3));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('Microphone')),
        matching: find.text('Fix'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fix'), findsNWidgets(2));

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Zema'), findsOneWidget);
    expect((await savedPreferences()).getBool('onboardingDone'), isTrue);
  });
}
