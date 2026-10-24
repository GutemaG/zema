import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/theme/zema_palette.dart';

// Expected values copied from the token table in docs/design-system.md, kept
// separate from lib/ so a typo in either place fails the test.
const _nightVigil = {
  'bg': 0xFF110D0B,
  'surface': 0xFF1C1613,
  'line': 0xFF2F2622,
  'text': 0xFFF2E8D7,
  'muted': 0xFFA39586,
  'faint': 0xFF7D7065,
  'primary': 0xFFE3AE4A,
  'onPrimary': 0xFF110D0B,
  'primaryText': 0xFFFFF4E0,
  'accent': 0xFFE3AE4A,
  'accentText': 0xFFE3AE4A,
  'soft': 0xFF3A2B17,
  'tile': 0xFF2A1E19,
  'tileFg': 0xFFE3AE4A,
  'shadow': 0x80000000,
};

const _wine = {
  'bg': 0xFF15090D,
  'surface': 0xFF22121A,
  'line': 0xFF3A2029,
  'text': 0xFFF4E7DD,
  'muted': 0xFFB3989A,
  'faint': 0xFF876C6F,
  'primary': 0xFFD9A441,
  'onPrimary': 0xFF15090D,
  'primaryText': 0xFFFFF1E2,
  'accent': 0xFFD9A441,
  'accentText': 0xFFE2B45B,
  'soft': 0xFF3B2418,
  'tile': 0xFF2C141C,
  'tileFg': 0xFFD9A441,
  'shadow': 0x80000000,
};

// Light versions: draft table in docs/design-system.md (2026-10-24).
const _nightVigilLight = {
  'bg': 0xFFFAF6EE,
  'surface': 0xFFFFFDF8,
  'line': 0xFFE6DCCB,
  'text': 0xFF1F1712,
  'muted': 0xFF6B5D50,
  'faint': 0xFF958676,
  'primary': 0xFFE3AE4A,
  'onPrimary': 0xFF1F1712,
  'primaryText': 0xFF120C08,
  'accent': 0xFFA87420,
  'accentText': 0xFF87570A,
  'soft': 0xFFF5E6C8,
  'tile': 0xFFF0E5D3,
  'tileFg': 0xFF87570A,
  'shadow': 0x1F000000,
};

const _wineLight = {
  'bg': 0xFFFAF3F2,
  'surface': 0xFFFFFCFB,
  'line': 0xFFEAD9D8,
  'text': 0xFF24141A,
  'muted': 0xFF735C60,
  'faint': 0xFF9C8689,
  'primary': 0xFFD9A441,
  'onPrimary': 0xFF24141A,
  'primaryText': 0xFF170A0F,
  'accent': 0xFFA06C24,
  'accentText': 0xFF85540C,
  'soft': 0xFFF5E3CF,
  'tile': 0xFFF2E1E1,
  'tileFg': 0xFF85540C,
  'shadow': 0x1F000000,
};

/// WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

Map<String, int> _tokens(ZemaColors c) => {
  'bg': c.bg.toARGB32(),
  'surface': c.surface.toARGB32(),
  'line': c.line.toARGB32(),
  'text': c.text.toARGB32(),
  'muted': c.muted.toARGB32(),
  'faint': c.faint.toARGB32(),
  'primary': c.primary.toARGB32(),
  'onPrimary': c.onPrimary.toARGB32(),
  'primaryText': c.primaryText.toARGB32(),
  'accent': c.accent.toARGB32(),
  'accentText': c.accentText.toARGB32(),
  'soft': c.soft.toARGB32(),
  'tile': c.tile.toARGB32(),
  'tileFg': c.tileFg.toARGB32(),
  'shadow': c.shadow.toARGB32(),
};

void main() {
  group('ZemaColors', () {
    test('has all 15 design-system tokens', () {
      expect(_tokens(ZemaColors.nightVigil).keys, unorderedEquals(_wine.keys));
      expect(_tokens(ZemaColors.nightVigil), hasLength(15));
    });

    test('Night Vigil matches the design system', () {
      expect(_tokens(ZemaColors.nightVigil), _nightVigil);
    });

    test('Wine matches the design system', () {
      expect(_tokens(ZemaColors.wine), _wine);
    });

    test('Night Vigil light matches the design system', () {
      expect(_tokens(ZemaColors.nightVigilLight), _nightVigilLight);
    });

    test('Wine light matches the design system', () {
      expect(_tokens(ZemaColors.wineLight), _wineLight);
    });

    const all = {
      'nightVigil': ZemaColors.nightVigil,
      'wine': ZemaColors.wine,
      'nightVigilLight': ZemaColors.nightVigilLight,
      'wineLight': ZemaColors.wineLight,
    };
    for (final MapEntry(key: name, value: c) in all.entries) {
      test('$name meets the contrast rules', () {
        void check(String pair, Color fg, Color bg, double minimum) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(minimum),
            reason: '$name $pair',
          );
        }

        for (final (label, bg) in [('bg', c.bg), ('surface', c.surface)]) {
          check('text on $label', c.text, bg, 4.5);
          check('muted on $label', c.muted, bg, 4.5);
          check('primaryText on $label', c.primaryText, bg, 4.5);
        }
        check('onPrimary on primary', c.onPrimary, c.primary, 4.5);
        check('accentText on soft', c.accentText, c.soft, 4.5);
        check('tileFg on tile', c.tileFg, c.tile, 3);
        // Dimmed sung lyrics only, at 17 px or larger.
        check('faint on bg', c.faint, c.bg, 3);
      });
    }

    test('lerp returns the end palettes at t = 0 and t = 1', () {
      const a = ZemaColors.nightVigil;
      const b = ZemaColors.wine;
      expect(_tokens(a.lerp(b, 0)), _nightVigil);
      expect(_tokens(a.lerp(b, 1)), _wine);
    });

    test('lerp interpolates every token when halfway', () {
      final mid = _tokens(ZemaColors.nightVigil.lerp(ZemaColors.wine, 0.5));
      for (final token in _nightVigil.keys) {
        final from = Color(_nightVigil[token]!);
        final to = Color(_wine[token]!);
        expect(
          mid[token],
          Color.lerp(from, to, 0.5)!.toARGB32(),
          reason: token,
        );
      }
    });

    test('lerp keeps this palette when other is null', () {
      expect(_tokens(ZemaColors.wine.lerp(null, 0.5)), _wine);
    });

    test('copyWith replaces only the given token', () {
      final copy = ZemaColors.nightVigil.copyWith(primary: Colors.red);
      expect(copy.primary, Colors.red);
      expect(
        _tokens(copy)..remove('primary'),
        Map.of(_nightVigil)..remove('primary'),
      );
    });
  });

  group('ZemaPalette', () {
    test('falls back to Night Vigil when nothing is saved', () {
      expect(ZemaPalette.fallback, ZemaPalette.nightVigil);
      expect(ZemaPalette.fallback.dark, same(ZemaColors.nightVigil));
    });

    test('maps each palette to its dark and light colors', () {
      expect(ZemaPalette.nightVigil.dark, same(ZemaColors.nightVigil));
      expect(ZemaPalette.wine.dark, same(ZemaColors.wine));
      expect(ZemaPalette.nightVigil.light, same(ZemaColors.nightVigilLight));
      expect(ZemaPalette.wine.light, same(ZemaColors.wineLight));
      expect(
        ZemaPalette.wine.colorsFor(Brightness.light),
        same(ZemaColors.wineLight),
      );
      expect(
        ZemaPalette.wine.colorsFor(Brightness.dark),
        same(ZemaColors.wine),
      );
    });
  });

  group('context.zemaColors', () {
    testWidgets('asserts with a helpful message when no theme has tokens', (
      tester,
    ) async {
      Object? error;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(),
          child: Builder(
            builder: (context) {
              try {
                context.zemaColors;
              } on AssertionError catch (e) {
                error = e;
              }
              return const SizedBox();
            },
          ),
        ),
      );
      expect(error, isA<AssertionError>());
      expect(error.toString(), contains('buildTheme()'));
    });
  });
}
