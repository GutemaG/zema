/// Shape, spacing and touch sizes from `docs/design-system.md`.
abstract final class ZemaRadius {
  /// Inputs, small cards.
  static const double small = 12;

  /// Cards, mini player.
  static const double medium = 16;

  /// Large tap areas.
  static const double large = 24;

  /// Fully rounded pills.
  static const double pill = 999;
}

abstract final class ZemaSpacing {
  /// Horizontal padding at the edge of a screen.
  static const double screenSide = 16;

  /// Height of a list row (track, folder, album).
  static const double listRow = 66;

  /// Minimum width and height of anything tappable.
  static const double minTap = 44;
}
