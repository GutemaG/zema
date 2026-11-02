import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import 'lyrics_step.dart';

/// What a correction changes, for S22: the lines [edited] adds, removes or
/// changes compared with the catalog's [base] (see [changedLines]), and the
/// [recordings] whose timing in [timings] the catalog would drop (see
/// [recordingsLosingTimings]).
class CorrectionChanges extends StatelessWidget {
  const CorrectionChanges({
    super.key,
    required this.base,
    required this.edited,
    this.recordings = const [],
    this.timings = const [],
  });

  final Song base;
  final Song edited;
  final List<Recording> recordings;
  final List<SyncTiming> timings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final changes = changedLines(base, edited);
    final losing = recordingsLosingTimings(edited, recordings, timings);
    final edits = {for (final s in edited.sections) s.id: s};
    final bases = {for (final s in base.sections) s.id: s};

    String blockOf(LineChange change) => switch (edits[change.sectionId]) {
      final section? => sectionLabel(l10n, edited.sections, section),
      null => sectionLabel(l10n, base.sections, bases[change.sectionId]!),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.contributeCorrectionChanges.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: colors.muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (changes.isEmpty)
          Text(
            l10n.contributeCorrectionNoChanges,
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        for (final change in changes)
          _ChangedLine(change: change, block: blockOf(change)),
        if (losing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(ZemaRadius.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.contributeCorrectionLosesTimings),
                for (final recording in losing)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 6),
                    child: Text(
                      [
                        recording.artist ?? l10n.unknownArtist,
                        if (recording.duration case final duration?)
                          formatDuration(duration),
                      ].join(' · '),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One changed line: what happened, its block, then the old line struck
/// through and the new one.
class _ChangedLine extends StatelessWidget {
  const _ChangedLine({required this.change, required this.block});

  final LineChange change;
  final String block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final what = switch (change.kind) {
      LineChangeKind.added => l10n.contributeCorrectionAdded,
      LineChangeKind.removed => l10n.contributeCorrectionRemoved,
      LineChangeKind.changed => l10n.contributeCorrectionChanged,
    };

    Widget line(LyricLine line, {required bool old}) => Text(
      [line.text, ?line.transliteration].join(' · '),
      style: textTheme.bodyLarge?.copyWith(
        color: old ? colors.muted : colors.text,
        decoration: old ? TextDecoration.lineThrough : null,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.small),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$what · $block',
            style: textTheme.labelMedium?.copyWith(
              color: change.kind == LineChangeKind.removed
                  ? colors.muted
                  : colors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          if (change.before case final before?) line(before, old: true),
          if (change.after case final after?) line(after, old: false),
        ],
      ),
    );
  }
}
