import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/theme/zema_theme.dart';
import 'package:zema/app/theme/zema_typography.dart';

List<TextStyle> _styles(TextTheme t) => [
  t.displayLarge,
  t.displayMedium,
  t.displaySmall,
  t.headlineLarge,
  t.headlineMedium,
  t.headlineSmall,
  t.titleLarge,
  t.titleMedium,
  t.titleSmall,
  t.bodyLarge,
  t.bodyMedium,
  t.bodySmall,
  t.labelLarge,
  t.labelMedium,
  t.labelSmall,
].nonNulls.toList();

void main() {
  for (final palette in ZemaPalette.values) {
    group('buildTheme(${palette.name})', () {
      final theme = buildTheme(palette);
      final c = palette.colors;

      test('is dark', () {
        expect(theme.brightness, Brightness.dark);
        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      test('maps the ColorScheme from the tokens', () {
        final scheme = theme.colorScheme;
        expect(scheme.surface, c.bg);
        expect(scheme.primary, c.primary);
        expect(scheme.onPrimary, c.onPrimary);
        expect(scheme.onSurface, c.text);
        expect(scheme.outline, c.line);
        expect(theme.scaffoldBackgroundColor, c.bg);
      });

      test('carries the palette as a ZemaColors extension', () {
        expect(theme.extension<ZemaColors>(), same(c));
      });

      test('uses Inter with Noto Sans Ethiopic as fallback', () {
        for (final style in _styles(theme.textTheme)) {
          expect(style.fontFamily, ZemaTypography.latinFamily);
          expect(
            style.fontFamilyFallback,
            contains(ZemaTypography.ethiopicFamily),
          );
        }
      });

      test('never sets line height below 1.4 (Ethiopic needs room)', () {
        final styles = _styles(theme.textTheme);
        expect(styles, isNotEmpty);
        for (final style in styles) {
          expect(style.height, greaterThanOrEqualTo(1.4), reason: '$style');
        }
      });
    });
  }
}
