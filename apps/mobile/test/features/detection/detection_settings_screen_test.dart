import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/application/detection_settings.dart';
import 'package:zema/features/detection/application/lyrics_overlay_sync.dart';
import 'package:zema/features/detection/data/background_access.dart';
import 'package:zema/features/detection/data/lyrics_overlay.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/detection/presentation/detection_settings_screen.dart';
import 'package:zema/features/identify/application/offline_catalog.dart';
import 'package:zema/features/identify/application/shared_fingerprints.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

class _FakeDetector extends NoPlaybackDetector {
  var on = true;
  var watched = {'com.google.android.youtube', 'org.telegram.messenger'};

  @override
  Future<bool> hasAccess() async => true;

  @override
  Future<bool> enabled() async => on;

  @override
  Future<void> setEnabled(bool on) async => this.on = on;

  @override
  Future<Set<String>> sources() async => watched;

  @override
  Future<void> setSources(Set<String> sources) async => watched = sources;
}

class _FakeOverlay extends NoLyricsOverlay {
  var saved = const OverlayAppearance();
  var opened = 0;

  @override
  Future<OverlayAppearance> appearance() async => saved;

  @override
  Future<void> setAppearance(OverlayAppearance appearance) async =>
      saved = appearance;

  @override
  Future<void> openSettings() async => opened++;
}

class _NoMicrophone implements MicrophoneAccess {
  @override
  Future<bool> granted() async => false;

  @override
  Future<void> fix() async {}
}

class _Battery implements BackgroundAccess {
  var asked = 0;
  var opened = 0;

  @override
  Future<bool> unrestricted() async => false;

  @override
  Future<void> allow() async => asked++;

  @override
  Future<PhoneBrand> brand() async => PhoneBrand.transsion;

  @override
  Future<void> openPhoneSettings() async => opened++;
}

void main() {
  test('phone brands from the manufacturer', () {
    expect(PhoneBrand.of('Xiaomi'), PhoneBrand.xiaomi);
    expect(PhoneBrand.of('TECNO'), PhoneBrand.transsion);
    expect(PhoneBrand.of('realme'), PhoneBrand.oppo);
    expect(PhoneBrand.of('Google'), PhoneBrand.other);
  });

  testWidgets('switches, apps, appearance and missing permissions', (
    tester,
  ) async {
    useScreen(tester, size: const Size(400, 2000));
    final detector = _FakeDetector();
    final overlay = _FakeOverlay();
    final battery = _Battery();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpThemed(
      tester,
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(memoryDatabase()),
          playbackDetectorProvider.overrideWithValue(detector),
          lyricsOverlayProvider.overrideWithValue(overlay),
          microphoneAccessProvider.overrideWithValue(_NoMicrophone()),
          otherAppsSupportedProvider.overrideWithValue(true),
          backgroundAccessProvider.overrideWithValue(battery),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const DetectionSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Fix'), findsNWidgets(3));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('Display over other apps')),
        matching: find.text('Fix'),
      ),
    );
    expect(overlay.opened, 1);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('Run in the background')),
        matching: find.text('Fix'),
      ),
    );
    expect(battery.asked, 1);

    await tester.tap(find.text('Battery saver steps'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Phone Master'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    expect(battery.opened, 1);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    Switch toggle(DetectionApp key) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle(DetectionApp.youtube).value, isTrue);
    expect(toggle(DetectionApp.youtubeMusic).value, isFalse);
    expect(toggle(DetectionApp.telegram).value, isTrue);

    await tester.tap(find.byKey(const ValueKey(DetectionApp.telegram)));
    await tester.pumpAndSettle();
    expect(detector.watched, {'com.google.android.youtube'});

    await tester.tap(find.text('Detect songs in other apps'));
    await tester.pumpAndSettle();
    expect(detector.on, isFalse);
    expect(toggle(DetectionApp.youtube).onChanged, isNull);

    await tester.tap(find.byTooltip('Larger text'));
    await tester.pumpAndSettle();
    expect(overlay.saved.textSize, 20);
    expect(find.text('20'), findsOneWidget);

    await tester.tap(find.text('Show lyrics as'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The lyrics bar'));
    await tester.pumpAndSettle();
    expect(overlay.saved.start, OverlayStart.bar);
    expect(overlay.saved.textSize, 20);

    await tester.tap(find.text('Share fingerprints of my songs'));
    await tester.pumpAndSettle();
    expect(preferences.getBool(ShareFingerprintsSetting.key), isTrue);

    expect(find.text('Up to 50 MB · None yet'), findsOneWidget);
    await tester.tap(find.text('Songs to identify offline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My library\'s songs only'));
    await tester.pumpAndSettle();
    expect(preferences.getString(OfflineBudgetSetting.key), 'libraryOnly');
  });
}
