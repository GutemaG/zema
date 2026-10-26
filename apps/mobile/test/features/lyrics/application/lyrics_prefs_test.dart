import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/lyrics/application/lyrics_prefs.dart';
import 'package:zema/features/lyrics/presentation/lyrics_options_sheet.dart';

Future<(ProviderContainer, SharedPreferences)> _container([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return (container, prefs);
}

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  group('Lyrics display', () {
    test('defaults: no transliteration, normal size', () async {
      final (c, _) = await _container();
      expect(c.read(lyricsDisplayProvider), const LyricsDisplay());
    });

    test('the transliteration switch is saved', () async {
      final (c, prefs) = await _container();
      await c
          .read(lyricsDisplayProvider.notifier)
          .setTransliteration(show: true);
      expect(c.read(lyricsDisplayProvider).showTransliteration, isTrue);
      expect(prefs.getBool(LyricsDisplayController.transliterationKey), true);
    });

    test('text size steps by 0.1 without drifting, within 0.8–1.6', () async {
      final (c, prefs) = await _container();
      final display = c.read(lyricsDisplayProvider.notifier);
      for (var i = 0; i < 3; i++) {
        await display.stepScale(1);
      }
      expect(c.read(lyricsDisplayProvider).textScale, 1.3);
      expect(prefs.getDouble(LyricsDisplayController.scaleKey), 1.3);
      for (var i = 0; i < 10; i++) {
        await display.stepScale(1);
      }
      expect(c.read(lyricsDisplayProvider).textScale, 1.6);
      expect(c.read(lyricsDisplayProvider).canGrow, isFalse);
      for (var i = 0; i < 20; i++) {
        await display.stepScale(-1);
      }
      expect(c.read(lyricsDisplayProvider).textScale, 0.8);
      expect(c.read(lyricsDisplayProvider).canShrink, isFalse);
    });

    test('saved values load, and out-of-range ones are clamped', () async {
      final (c, _) = await _container({
        LyricsDisplayController.transliterationKey: true,
        LyricsDisplayController.scaleKey: 3.0,
      });
      expect(
        c.read(lyricsDisplayProvider),
        const LyricsDisplay(showTransliteration: true, textScale: 1.6),
      );
    });
  });

  group('Sync offset', () {
    test('steps of 0.5 s, saved per recording', () async {
      final (c, prefs) = await _container();
      await c.read(lyricsOffsetProvider('a').notifier).nudge(3);
      await c.read(lyricsOffsetProvider('b').notifier).nudge(-1);
      expect(c.read(lyricsOffsetProvider('a')), _ms(1500));
      expect(c.read(lyricsOffsetProvider('b')), _ms(-500));
      expect(prefs.getInt('lyricsOffset.a'), 1500);
      expect(prefs.getInt('lyricsOffset.b'), -500);
    });

    test('clamped to ±10 s', () async {
      final (c, _) = await _container({'lyricsOffset.a': 60000});
      expect(c.read(lyricsOffsetProvider('a')), const Duration(seconds: 10));
      await c.read(lyricsOffsetProvider('a').notifier).nudge(1);
      expect(c.read(lyricsOffsetProvider('a')), const Duration(seconds: 10));
      await c.read(lyricsOffsetProvider('a').notifier).nudge(-100);
      expect(c.read(lyricsOffsetProvider('a')), const Duration(seconds: -10));
    });

    test('reset goes back to zero and forgets the value', () async {
      final (c, prefs) = await _container({'lyricsOffset.a': 1000});
      await c.read(lyricsOffsetProvider('a').notifier).reset();
      expect(c.read(lyricsOffsetProvider('a')), Duration.zero);
      expect(prefs.containsKey('lyricsOffset.a'), isFalse);
    });

    test('formatOffset shows the sign and one decimal', () {
      expect(formatOffset(_ms(1000)), '+1.0 s');
      expect(formatOffset(_ms(-500)), '−0.5 s');
      expect(formatOffset(Duration.zero), '0.0 s');
    });
  });
}
