import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../application/artwork_provider.dart';

/// A track's album art, loaded lazily. Until it loads, or when there is none,
/// a `tile` square with the title's first letter in `tileFg`.
class TrackArt extends ConsumerWidget {
  const TrackArt({
    super.key,
    required this.track,
    required this.size,
    this.radius = 8,
  });

  final Track track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.zemaColors;
    final image = ref.watch(artworkProvider(track.mediaStoreId)).value;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final shape = BorderRadius.circular(radius);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: image == null
            // A rounded box is cheaper to draw than a clip, and most rows in
            // a long list show the placeholder.
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: shape,
                ),
                child: Center(
                  child: Text(
                    _letter(track.title),
                    style: TextStyle(
                      color: colors.tileFg,
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
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

  static String _letter(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '♪';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
