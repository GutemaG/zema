import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/artist_grouping.dart';
import '../artists_view.dart';
import 'track_art.dart';

/// An artist with a round avatar and a song count; opens the artist page
/// in the current tab (see [AppRoutes.detailBase]), or runs [onTap].
class ArtistRow extends StatelessWidget {
  const ArtistRow({super.key, required this.artist, this.onTap});

  final Artist artist;

  /// Runs before the page opens (Search saves the query).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final name = artistName(l10n, artist);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () {
          onTap?.call();
          final base = AppRoutes.detailBase(GoRouterState.of(context).uri.path);
          unawaited(context.push(AppRoutes.artist(artist.name, base: base)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
          ),
          child: Row(
            children: [
              TrackArt(track: artist.cover, size: 46, radius: 23, label: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: colors.text),
                    ),
                    Text(
                      l10n.librarySongCount(artist.tracks.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
