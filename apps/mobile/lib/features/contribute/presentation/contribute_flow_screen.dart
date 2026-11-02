import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/drafts.dart';
import 'contribute_screen.dart';
import 'lyrics_step.dart';
import 'recording_step.dart';
import 'review_step.dart';
import 'sync_step.dart';

/// The four-step flow (S19–S22) for draft [id], opened at its step. Every
/// change is saved on the phone as it is made.
class ContributeFlowScreen extends ConsumerWidget {
  const ContributeFlowScreen({super.key, required this.id});

  /// Null when the route had no valid id.
  final int? id;

  static void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.contribute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    final draft = id == null
        ? const AsyncData<ContributionDraft?>(null)
        : ref.watch(draftEditorProvider(id));
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => _close(context)),
        title: Text(switch (draft.value?.kind) {
          ContributionKind.editLyrics => l10n.contributeCorrectionSuggest,
          ContributionKind.recording => l10n.contributeFlowRecordingTitle,
          ContributionKind.syncTiming => l10n.contributeFlowSyncTitle,
          _ => l10n.contributeAddLyrics,
        }),
      ),
      body: SafeArea(
        top: false,
        child: switch (draft) {
          AsyncData(value: final draft?) => Column(
            children: [
              StepStrip(
                current: draft.step,
                onBack: (step) => ref
                    .read(draftEditorProvider(id!).notifier)
                    .edit((draft) => draft.copyWith(step: step)),
              ),
              Expanded(
                child: switch (draft.step) {
                  DraftStep.lyrics => LyricsStep(id: id!, draft: draft),
                  DraftStep.recording => RecordingStep(id: id!, draft: draft),
                  DraftStep.sync => SyncStep(id: id!, draft: draft),
                  DraftStep.review => ReviewStep(id: id!, draft: draft),
                },
              ),
            ],
          ),
          AsyncData() || AsyncError() => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.contributeDraftGone,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// The four steps across the top, done and current ones lit.
class StepStrip extends StatelessWidget {
  const StepStrip({super.key, required this.current, this.onBack});

  final DraftStep current;

  /// Goes back to an earlier step when it's tapped.
  final ValueChanged<DraftStep>? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        4,
        ZemaSpacing.screenSide,
        8,
      ),
      child: Row(
        children: [
          for (final step in DraftStep.values) ...[
            if (step != DraftStep.values.first) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                selected: step == current,
                button: step.index < current.index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: step.index < current.index && onBack != null
                      ? () => onBack!(step)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: step.index <= current.index
                              ? colors.primary
                              : colors.line,
                          borderRadius: BorderRadius.circular(ZemaRadius.pill),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        draftStepName(l10n, step),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: step == current ? colors.text : colors.muted,
                          fontWeight: step == current ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
