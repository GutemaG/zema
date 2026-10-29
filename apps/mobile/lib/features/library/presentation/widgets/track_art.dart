import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../application/artwork_provider.dart';

/// A track's album art, loaded lazily. Until it loads, or when there is none,
/// a [LetterTile] of [label] (the title by default).
class TrackArt extends ConsumerWidget {
  const TrackArt({
    super.key,
    required this.track,
    required this.size,
    this.radius = 8,
    this.label,
  });

  final Track track;
  final double size;
  final double radius;

  /// The text whose first letter the placeholder shows, e.g. an album or
  /// artist name.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(artworkProvider(track.mediaStoreId)).value;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final shape = BorderRadius.circular(radius);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: image == null
            // A rounded box is cheaper to draw than a clip, and most rows in
            // a long list show the placeholder.
            ? LetterTile(
                label: label ?? track.title,
                size: size,
                radius: radius,
              )
            : ClipRRect(
                borderRadius: shape,
                child: Image.memory(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: pixels,
                  gaplessPlayback: true,
                ),
              ),
      ),
    );
  }
}

/// A `tile` square with the first letter of [label] in `tileFg`, standing in
/// for missing art.
class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.label,
    required this.size,
    this.radius = 8,
  });

  final String label;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tile,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Text(
            _letter(label),
            style: TextStyle(
              color: colors.tileFg,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
  }

  static String _letter(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '♪';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
