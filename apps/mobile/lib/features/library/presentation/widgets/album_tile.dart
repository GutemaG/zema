import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/album_grouping.dart';
import 'track_art.dart';

/// The name to show for [album].
String albumTitle(AppLocalizations l10n, Album album) =>
    album.title ?? l10n.unknownAlbum;

/// The artist line for [album]: its artist, "Various artists" or "Unknown
/// artist".
String albumArtist(AppLocalizations l10n, Album album) => album.variousArtists
    ? l10n.variousArtists
    : album.artist ?? l10n.unknownArtist;

/// A cover with the album name and artist below it, for grids and rows.
class AlbumTile extends StatelessWidget {
  const AlbumTile({
    super.key,
    required this.album,
    required this.width,
    required this.onTap,
  });

  final Album album;
  final double width;
  final VoidCallback onTap;

  /// Height of the two text lines under the cover at the current text
  /// size, so grids can size their tiles without overflowing.
  static double textHeight(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style) {
      // Measured with Latin and Ethiopic, as laid out, rather than computed
      // from the font size: line heights are rounded by the font metrics.
      final painter = TextPainter(
        text: TextSpan(text: 'Ag ሀ', style: base.merge(style)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return (8 + line(textTheme.bodyLarge) + line(textTheme.bodySmall))
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final title = albumTitle(l10n, album);
    final artist = albumArtist(l10n, album);
    // One node reading "name, artist" for screen readers.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrackArt(
                  track: album.cover,
                  size: width,
                  radius: 12,
                  label: title,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(color: colors.text),
                ),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
