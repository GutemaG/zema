import 'package:flutter/material.dart';

import 'theme/zema_colors.dart';
import 'theme/zema_palette.dart';
import 'theme/zema_spacing.dart';
import 'theme/zema_theme.dart';

/// Root widget of the app.
class ZemaApp extends StatelessWidget {
  const ZemaApp({super.key, this.palette = ZemaPalette.fallback});

  /// Active palette. Comes from saved settings once Settings exists (bolt 3).
  final ZemaPalette palette;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App name, not a translatable UI string.
      title: 'Zema',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      themeMode: ThemeMode.dark,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary first screen until the app shell lands in bolt 2. Shows Latin
/// and Ethiopic sample text so theme and fonts can be checked on a device.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.zemaColors;
    // Sample text only; replaced by localized screens in bolt 2.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZemaSpacing.screenSide,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ዜማ',
                  style: textTheme.displaySmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text('Zema', style: textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
