import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../application/playlists.dart';
import 'track_art.dart';

/// A playlist's cover: four album covers in a grid, one cover, or a
/// playlist icon when the playlist is empty (see [Playlist.covers]).
class PlaylistCollage extends StatelessWidget {
  const PlaylistCollage({
    super.key,
    required this.playlist,
    required this.size,
    this.radius = 8,
  });

  final Playlist playlist;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final covers = playlist.covers;
    return switch (covers.length) {
      0 => ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.tile,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.queue_music,
              size: size * 0.45,
              color: colors.tileFg,
            ),
          ),
        ),
      ),
      1 => TrackArt(
        track: covers.single,
        size: size,
        radius: radius,
        label: playlist.name,
      ),
      _ => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.square(
          dimension: size,
          child: Column(
            children: [
              for (final row in [covers.sublist(0, 2), covers.sublist(2, 4)])
                Row(
                  children: [
                    for (final track in row)
                      TrackArt(track: track, size: size / 2, radius: 0),
                  ],
                ),
            ],
          ),
        ),
      ),
    };
  }
}
