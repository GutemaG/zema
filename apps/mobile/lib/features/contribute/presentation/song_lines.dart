import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'lyrics_step.dart';

/// [song]'s lines in play order under their block labels, for S22 and
/// S23m; line [current] (an index in the play order) is highlighted.
class SongLines extends StatelessWidget {
  const SongLines({super.key, required this.song, this.current});

  final Song song;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in expandPlayOrder(song).occurrences) ...[
          if (line.startsSection)
            Padding(
              padding: EdgeInsets.only(
                top: line.index == 0 ? 0 : 12,
                bottom: 2,
              ),
              child: Text(
                switch (song.sections
                    .where((s) => s.id == line.sectionId)
                    .firstOrNull) {
                  final section? => sectionLabel(
                    l10n,
                    song.sections,
                    section,
                  ).toUpperCase(),
                  null => '',
                },
                style: textTheme.labelSmall?.copyWith(
                  color: colors.accentText,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Text(
            line.line.text,
            style: line.index == current
                ? textTheme.bodyLarge?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  )
                : textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}
