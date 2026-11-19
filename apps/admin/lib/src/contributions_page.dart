import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import 'choice.dart';
import 'format.dart';
import 'session.dart';
import 'song_views.dart';
import 'strings.dart';

final queueKindProvider =
    NotifierProvider<Choice<ContributionKind?>, ContributionKind?>(
      () => Choice(null),
    );

/// Others' pending contributions, oldest first, of the chosen kind.
final reviewQueueProvider =
    FutureProvider.autoDispose<List<QueuedContribution>>(
      (ref) => ref
          .watch(contributionRepositoryProvider)
          .queue(kind: ref.watch(queueKindProvider)),
    );

final selectedContributionProvider = NotifierProvider<Choice<String?>, String?>(
  () => Choice(null),
);

String kindLabel(ContributionKind kind) => switch (kind) {
  ContributionKind.newSong => Strings.newSong,
  ContributionKind.editLyrics => Strings.editLyrics,
  ContributionKind.recording => Strings.recording,
  ContributionKind.syncTiming => Strings.syncTiming,
};

String titleOf(QueuedContribution item) =>
    item.contribution.song?.title ??
    item.currentSong?.song.title ??
    item.contribution.songId ??
    '';

/// The queue beside the selected contribution; on a narrow screen the
/// contribution opens on its own page.
class ContributionsPage extends ConsumerWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _Queue(
        onOpen: wide
            ? null
            : (item) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(titleOf(item))),
                    body: ContributionReview(
                      item: item,
                      onDone: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
      );
      if (!wide) return list;
      final selected = ref.watch(selectedContributionProvider);
      final item = ref
          .watch(reviewQueueProvider)
          .value
          ?.where((c) => c.id == selected)
          .firstOrNull;
      return Row(
        children: [
          SizedBox(width: 360, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            child: item == null
                ? const Center(child: Text(Strings.pickOne))
                : ContributionReview(key: ValueKey(item.id), item: item),
          ),
        ],
      );
    },
  );
}

class _Queue extends ConsumerWidget {
  const _Queue({this.onOpen});

  /// Opens a contribution on its own page; null to select it beside.
  final void Function(QueuedContribution item)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(queueKindProvider);
    final selected = ref.watch(selectedContributionProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in [null, ...ContributionKind.values])
                ChoiceChip(
                  label: Text(k == null ? Strings.all : kindLabel(k)),
                  selected: kind == k,
                  onSelected: (_) =>
                      ref.read(queueKindProvider.notifier).pick(k),
                ),
              IconButton(
                tooltip: Strings.reload,
                onPressed: () => ref.invalidate(reviewQueueProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (ref.watch(reviewQueueProvider)) {
            AsyncData(value: final items) when items.isEmpty => const Center(
              child: Text(Strings.queueEmpty),
            ),
            AsyncData(value: final items) => ListView(
              children: [
                for (final item in items)
                  ListTile(
                    selected: item.id == selected,
                    title: Text(titleOf(item)),
                    subtitle: Text(
                      [
                        kindLabel(item.kind),
                        '${Strings.byAuthor} ${item.authorName ?? Strings.anonymous}',
                        formatAge(item.submittedAt),
                        if (item.revision > 1) Strings.resubmitted,
                      ].join(' · '),
                      style: TextStyle(color: muted),
                    ),
                    trailing: item.basedOnOlderVersion
                        ? const Icon(Icons.warning_amber, size: 18)
                        : null,
                    onTap: () {
                      ref
                          .read(selectedContributionProvider.notifier)
                          .pick(item.id);
                      onOpen?.call(item);
                    },
                  ),
              ],
            ),
            AsyncError(:final error) => _Failed(error: error),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(error is NetworkFailure ? Strings.offline : '$error'),
        TextButton(
          onPressed: () => ref.invalidate(reviewQueueProvider),
          child: const Text(Strings.retry),
        ),
      ],
    ),
  );
}

/// One contribution: what it adds or changes, and the decision.
class ContributionReview extends ConsumerStatefulWidget {
  const ContributionReview({super.key, required this.item, this.onDone});

  final QueuedContribution item;

  /// Called after a decision is saved.
  final VoidCallback? onDone;

  @override
  ConsumerState<ContributionReview> createState() => _ContributionReviewState();
}

class _ContributionReviewState extends ConsumerState<ContributionReview> {
  final _note = TextEditingController();
  String? _noteError;
  var _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(ReviewDecision decision) async {
    final note = _note.text.trim();
    if (decision.needsNote && note.isEmpty) {
      setState(() => _noteError = Strings.noteRequired);
      return;
    }
    setState(() {
      _noteError = null;
      _busy = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    String? message;
    var reload = false;
    try {
      await ref
          .read(contributionRepositoryProvider)
          .review(widget.item.id, decision, note: note.isEmpty ? null : note);
      message = switch (decision) {
        ReviewDecision.approve => Strings.approved,
        ReviewDecision.requestChanges => Strings.sentBack,
        ReviewDecision.reject => Strings.rejected,
      };
      reload = true;
    } on ContributionFailure catch (e) {
      message = switch (e.code) {
        'already_reviewed' => Strings.alreadyReviewed,
        'own_contribution' => Strings.ownContribution,
        'unknown_song' => Strings.songGone,
        'note_required' => Strings.noteRequired,
        _ => e.code,
      };
      reload = e.code == 'already_reviewed';
    } on NetworkFailure {
      message = Strings.offline;
    } on ZemaFailure catch (e) {
      message = e.message;
    }
    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (reload) {
      ref.read(selectedContributionProvider.notifier).pick(null);
      ref.invalidate(reviewQueueProvider);
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final c = item.contribution;
    final current = item.currentSong;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final timingSong = c.song ?? current?.song;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(titleOf(item), style: text.headlineSmall),
              Text(
                [
                  kindLabel(item.kind),
                  ?(c.song ?? current?.song)?.artist,
                  '${Strings.byAuthor} ${item.authorName ?? Strings.anonymous}',
                  formatAge(item.submittedAt),
                  if (item.revision > 1)
                    '${Strings.resubmitted} (${item.revision})',
                ].join(' · '),
                style: muted,
              ),
              if (item.basedOnOlderVersion)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(Strings.olderVersion),
                ),
              if (item.previousNote case final note?) ...[
                const SectionTitle(Strings.lastNote),
                Text(note),
              ],
              if (c.kind == ContributionKind.editLyrics && current != null) ...[
                const SectionTitle(Strings.changes),
                LineChanges(base: current.song, edited: c.song!),
                if (recordingsLosingTimings(
                      c.song!,
                      current.recordings,
                      current.timings,
                    )
                    case final losing when losing.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(Strings.losesTimings),
                  for (final r in losing) RecordingInfo(r),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = [
                      [
                        const SectionTitle(Strings.current),
                        SongLines(current.song),
                      ],
                      [
                        const SectionTitle(Strings.submitted),
                        SongLines(c.song!),
                      ],
                    ];
                    if (constraints.maxWidth < 640) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final col in columns) ...col],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final col in columns)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: col,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ] else if (c.song case final song?) ...[
                const SectionTitle(Strings.submitted),
                SongLines(song),
              ],
              if (c.recording case final r?) ...[
                const SectionTitle(Strings.recording),
                RecordingInfo(r),
              ] else if (c.timing case final t?)
                if (current?.recordings
                        .where((r) => r.id == t.recordingId)
                        .firstOrNull
                    case final r?) ...[
                  const SectionTitle(Strings.recording),
                  RecordingInfo(r),
                ],
              if (c.timing case final t?) ...[
                const SectionTitle(Strings.timing),
                if (timingSong != null)
                  TimingTable(song: timingSong, timing: t),
              ] else if (c.kind == ContributionKind.recording) ...[
                const SectionTitle(Strings.timing),
                const Text(Strings.noTiming),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _note,
                enabled: !_busy,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: Strings.note,
                  errorText: _noteError,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _decide(ReviewDecision.reject),
                    child: const Text(Strings.reject),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _decide(ReviewDecision.requestChanges),
                    child: const Text(Strings.requestChanges),
                  ),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _decide(ReviewDecision.approve),
                    child: const Text(Strings.approve),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
