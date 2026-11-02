import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/drafts.dart';
import '../application/own_copies.dart';
import 'lyrics_step.dart';

/// How a draft's timings will be sent, as S22 shows them.
enum SyncStatus { synced, textOnly, youtube }

/// [draft]'s [SyncStatus]: a YouTube recording can't be synced, and a draft
/// with a line still untimed is sent as text only.
SyncStatus syncStatusOf(ContributionDraft draft) => switch (draft.recording) {
  Recording(source: RecordingSource.youtube) => SyncStatus.youtube,
  final Recording _ when draft.synced => SyncStatus.synced,
  _ => SyncStatus.textOnly,
};

/// Why sending failed, in words that name the problem. The draft is kept
/// in every case.
String submitProblem(AppLocalizations l10n, Object error) => switch (error) {
  NetworkFailure() => l10n.contributeSubmitOffline,
  AuthFailure() => l10n.contributeSubmitSignIn,
  ContributionFailure(:final error?) => switch (error) {
    ContributionError.tooManyOpen => l10n.contributeSubmitTooManyOpen(
      maxOpenContributions,
    ),
    ContributionError.tooManyToday => l10n.contributeSubmitTooManyToday(
      maxContributionsPerDay,
    ),
    ContributionError.titleRequired ||
    ContributionError.titleTooLong ||
    ContributionError.fieldTooLong ||
    ContributionError.noSections ||
    ContributionError.emptySection ||
    ContributionError.badSection ||
    ContributionError.tooManyLines ||
    ContributionError.playOrderEmpty ||
    ContributionError.playOrderUnknownSection ||
    ContributionError.missingSong => l10n.contributeSubmitFixLyrics,
    ContributionError.badRecording ||
    ContributionError.badVideoId ||
    ContributionError.missingRecording ||
    ContributionError.unknownRecording => l10n.contributeSubmitFixRecording,
    ContributionError.timingCount ||
    ContributionError.timingOrder ||
    ContributionError.timingPastDuration ||
    ContributionError.youtubeNotSynced ||
    ContributionError.missingTiming => l10n.contributeSubmitFixSync,
    ContributionError.notSignedIn => l10n.contributeSubmitSignIn,
    _ => l10n.contributeSubmitRefused,
  },
  ContributionFailure() => l10n.contributeSubmitRefused,
  _ => l10n.contributeSubmitFailed,
};

/// S22, step 4: the song, the lyrics in play order, the recording and the
/// sync status, each with Edit, and Submit for review.
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key, required this.id, required this.draft});

  final int id;
  final ContributionDraft draft;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  var _sending = false;

  /// Why the last try failed.
  String? _problem;

  void _goTo(DraftStep step) => ref
      .read(draftEditorProvider(widget.id).notifier)
      .edit((draft) => draft.copyWith(step: step));

  Future<void> _submit() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _sending = true;
      _problem = null;
    });
    try {
      await ref.read(draftEditorProvider(widget.id).notifier).flush();
      await submitDraft(ref, widget.id, widget.draft);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _problem = submitProblem(l10n, e);
        });
      }
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.contributeSubmitSent)));
    router.go(AppRoutes.contribute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final draft = widget.draft;
    final song = draft.song;
    final recording = draft.recording;
    final status = syncStatusOf(draft);
    final details = [
      ?_blankToNull(song.artist),
      ?_blankToNull(song.album),
    ].join(' · ');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              4,
              ZemaSpacing.screenSide,
              8,
            ),
            children: [
              Text(
                l10n.contributeReviewIntro,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 12),
              _Section(
                title: l10n.contributeReviewSong,
                editLabel: l10n.contributeReviewEditSong,
                onEdit: _sending ? null : () => _goTo(DraftStep.lyrics),
                children: [
                  Text(draft.title, style: textTheme.titleMedium),
                  if (_blankToNull(song.transliteration) case final latin?)
                    Text(
                      latin,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
              _Section(
                title: l10n.contributeReviewLyrics,
                editLabel: l10n.contributeReviewEditLyrics,
                onEdit: _sending ? null : () => _goTo(DraftStep.lyrics),
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
                    Text(line.line.text, style: textTheme.bodyLarge),
                  ],
                ],
              ),
              _Section(
                title: l10n.contributeReviewRecording,
                editLabel: l10n.contributeReviewEditRecording,
                onEdit: _sending ? null : () => _goTo(DraftStep.recording),
                children: [
                  if (recording == null)
                    Text(
                      l10n.contributeReviewNoRecording,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    )
                  else ...[
                    Text(
                      recording.source == RecordingSource.youtube
                          ? draft.videoTitle ??
                                l10n.contributeReviewYoutubeVideo
                          : recording.fileName ?? '',
                      style: textTheme.bodyLarge,
                    ),
                    if ([
                          ?_blankToNull(recording.artist),
                          if (recording.duration case final d?)
                            formatDurationText(d),
                        ].join(' · ')
                        case final more when more.isNotEmpty)
                      Text(
                        more,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                  ],
                ],
              ),
              _Section(
                title: l10n.contributeReviewSync,
                editLabel: l10n.contributeReviewEditSync,
                // Timings need a recording that plays in Zema.
                onEdit: _sending
                    ? null
                    : () => _goTo(
                        recording == null ||
                                recording.source == RecordingSource.youtube
                            ? DraftStep.recording
                            : DraftStep.sync,
                      ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(ZemaRadius.pill),
                      ),
                      child: Text(
                        switch (status) {
                          SyncStatus.synced => l10n.contributeReviewSynced,
                          SyncStatus.textOnly => l10n.contributeReviewTextOnly,
                          SyncStatus.youtube => l10n.contributeReviewYoutube,
                        },
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.accentText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_problem case final problem?) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.soft,
                      borderRadius: BorderRadius.circular(ZemaRadius.small),
                    ),
                    child: Text(problem),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _sending ? null : () => unawaited(_submit()),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZemaRadius.large),
                    ),
                    textStyle: textTheme.titleMedium,
                  ),
                  child: _sending
                      ? SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            semanticsLabel: l10n.contributeSubmitSending,
                          ),
                        )
                      : Text(
                          l10n.contributeSubmit,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One part of the review: a title with Edit, and what it holds.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.editLabel,
    required this.onEdit,
    required this.children,
  });

  final String title;

  /// Edit's label for screen readers, naming the part.
  final String editLabel;
  final VoidCallback? onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.medium),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
              Semantics(
                container: true,
                label: editLabel,
                excludeSemantics: true,
                button: true,
                enabled: onEdit != null,
                onTap: onEdit,
                child: TextButton(
                  onPressed: onEdit,
                  child: Text(l10n.contributeReviewEdit),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

String? _blankToNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
