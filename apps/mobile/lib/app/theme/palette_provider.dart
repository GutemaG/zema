import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';
import 'zema_palette.dart';

/// The active palette, from the user's settings (Night Vigil by default).
final paletteProvider = Provider<ZemaPalette>(
  (ref) => ref.watch(settingsProvider.select((s) => s.palette)),
);

/// Light, dark or follow the phone, from the user's settings (System by
/// default).
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);
