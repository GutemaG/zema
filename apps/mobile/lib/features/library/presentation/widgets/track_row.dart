import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/format_duration.dart';
import 'track_art.dart';

/// One song in a list: art (or a track [number]), title, artist · duration,
/// and an optional [trailing] widget. The current song's title is
/// highlighted. Every row has the same [height], so lists can jump to any
/// position instantly.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    this.isCurrent = false,
    this.number,
    this.trailing,
  });

  static const double height = ZemaSpacing.listRow;

  final Track track;
  final VoidCallback onTap;
  final bool isCurrent;

  /// Shown instead of the art, e.g. the position in an album.
  final int? number;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final artist = track.artist ?? l10n.unknownArtist;
    final duration = formatDuration(track.duration);
    return Semantics(
      button: true,
      selected: isCurrent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZemaSpacing.screenSide,
            ),
            child: Row(
              children: [
                if (number case final number?)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$number',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isCurrent ? colors.primaryText : colors.muted,
                      ),
                    ),
                  )
                else
                  TrackArt(track: track, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: isCurrent ? colors.primaryText : colors.text,
                          fontWeight: isCurrent ? FontWeight.w600 : null,
                        ),
                      ),
                      Text(
                        '$artist · $duration',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.graphic_eq, size: 20, color: colors.primaryText),
                ],
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
