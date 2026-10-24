import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zema_palette.dart';

/// The active palette. Always the fallback until Settings exists (bolt 3),
/// which overrides this from saved preferences.
final paletteProvider = Provider<ZemaPalette>((ref) => ZemaPalette.fallback);
