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

/// WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final palette in ZemaPalette.values) {
    for (final brightness in Brightness.values) {
      group('buildTheme(${palette.name}, ${brightness.name})', () {
        final theme = buildTheme(palette, brightness);
        final c = palette.colorsFor(brightness);

        test('has the requested brightness', () {
          expect(theme.brightness, brightness);
          expect(theme.colorScheme.brightness, brightness);
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

        test('snackbars use the opposite brightness, readable', () {
          final scheme = theme.colorScheme;
          final inverse = palette.colorsFor(
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          );
          expect(scheme.inverseSurface, inverse.bg);
          expect(scheme.onInverseSurface, inverse.text);
          expect(scheme.inversePrimary, inverse.accentText);
          expect(
            _contrast(scheme.onInverseSurface, scheme.inverseSurface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.inversePrimary, scheme.inverseSurface),
            greaterThanOrEqualTo(4.5),
            reason: 'snackbar actions such as Undo',
          );
        });

        test('text buttons use accentText', () {
          final style = theme.textButtonTheme.style!;
          expect(style.foregroundColor?.resolve({}), c.accentText);
          expect(_contrast(c.accentText, c.bg), greaterThanOrEqualTo(4.5));
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
}
