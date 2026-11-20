import 'package:flutter/painting.dart';

/// Backgrounds for lyrics clips of songs without cover art: deep two-tone
/// gradients (top, bottom) that keep light text readable. A song always gets
/// the same one.
const clipGradients = <(Color, Color)>[
  (Color(0xFF16606F), Color(0xFF06242B)),
  (Color(0xFF34398C), Color(0xFF12143A)),
  (Color(0xFF7A2346), Color(0xFF2A0B18)),
  (Color(0xFF235E3A), Color(0xFF0A2214)),
  (Color(0xFF8E3F17), Color(0xFF331405)),
  (Color(0xFF55287A), Color(0xFF1C0C2A)),
  (Color(0xFF285480), Color(0xFF0C1C2E)),
];

/// Plain backgrounds a clip can use instead of the song's colours.
const clipPlainColors = <Color>[
  Color(0xFF110D0B),
  Color(0xFF1B2A4A),
  Color(0xFF0F3B36),
  Color(0xFF4A1426),
  Color(0xFF3A2B17),
  Color(0xFF2E2E2E),
];

/// Colours for a clip's lyrics; all light, for dark or dimmed backgrounds.
const clipTextColors = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFF2E8D7),
  Color(0xFFF3C969),
  Color(0xFFA8E6CF),
  Color(0xFFF7B2C4),
];
