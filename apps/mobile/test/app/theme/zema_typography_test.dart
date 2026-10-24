import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_typography.dart';

const _fontSize = 20.0;
const _noto = TextStyle(fontFamily: ZemaTypography.ethiopicFamily);

/// Loads a bundled family from the asset bundle, which also proves the
/// pubspec declares it.
Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontSize: _fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  // The test font draws every glyph as a square exactly one em wide, so a
  // string that falls back to it measures `length * fontSize`. Real glyphs
  // from the bundled fonts give different widths.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
    await _loadFamily(ZemaTypography.latinFamily, [
      for (final w in weights) 'Inter-$w.ttf',
    ]);
    await _loadFamily(ZemaTypography.ethiopicFamily, [
      for (final w in weights) 'NotoSansEthiopic-$w.ttf',
    ]);
  });

  final theme = ZemaTypography.textTheme(
    text: Colors.white,
    muted: Colors.grey,
  );
  final body = theme.bodyLarge!;

  group('ZemaTypography', () {
    test('Latin text renders with bundled Inter', () {
      expect(_width('Zema', body), isNot(4 * _fontSize));
    });

    test('Ethiopic text renders with bundled Noto Sans Ethiopic', () {
      expect(_width('ዜማ', _noto), isNot(2 * _fontSize));
      expect(_width('ስብሐት ለእግዚአብሔር', _noto), greaterThan(0));
    });

    test('Ethiopic in an Inter style falls back to Noto Sans Ethiopic', () {
      expect(_width('ዜማ', body), _width('ዜማ', _noto));
    });

    test('mixed Latin and Ethiopic renders both scripts', () {
      final mixed = _width('Zema ዜማ', body);
      final parts = _width('Zema ', body) + _width('ዜማ', body);
      expect(mixed, moreOrLessEquals(parts, epsilon: 0.5));
      expect(mixed, isNot(7 * _fontSize));
    });

    test('Ethiopic line height is at least 1.4', () {
      expect(ZemaTypography.ethiopicLineHeight, greaterThanOrEqualTo(1.4));
      final painter = TextPainter(
        text: TextSpan(
          text: 'ዜማ',
          style: body.copyWith(fontSize: _fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(painter.height, greaterThanOrEqualTo(_fontSize * 1.4));
      painter.dispose();
    });
  });
}
