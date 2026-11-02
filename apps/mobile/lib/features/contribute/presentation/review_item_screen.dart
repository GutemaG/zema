import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/moderation.dart';
import 'correction_changes.dart';
import 'my_contributions_screen.dart';
import 'review_queue_screen.dart';
import 'song_lines.dart';
import 'sync_step.dart';

/// One item of S23m: what it adds or changes, a checklist, and Approve /
/// Request changes / Reject (the last two with a comment). It closes once
/// decided, or when someone else decided first.
class ReviewItemScreen extends ConsumerStatefulWidget {
  const ReviewItemScreen({super.key, required this.id});

  final String? id;

  @override
  ConsumerState<ReviewItemScreen> createState() => _ReviewItemScreenState();
}

class _ReviewItemScreenState extends ConsumerState<ReviewItemScreen> {
  final _checked = <int>{};
  bool _sending = false;

  Future<void> _decide(QueuedContribution item, ReviewDecision decision) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    String? note;
    if (decision.needsNote) {
      note = await showDialog<String>(
        context: context,
        builder: (_) => _NoteDialog(
          title: decision == ReviewDecision.reject
              ? l10n.reviewNoteRejectTitle
              : l10n.reviewNoteChangesTitle,
        ),
      );
      if (note == null || !mounted) return;
    }
    setState(() => _sending = true);
    String message;
    var close = true;
    try {
      await ref
          .read(reviewQueueProvider.notifier)
          .decide(item.id, decision, note: note);
      message = switch (decision) {
        ReviewDecision.approve => l10n.reviewApproved,
        ReviewDecision.requestChanges => l10n.reviewChangesRequested,
        ReviewDecision.reject => l10n.reviewRejected,
      };
    } on ContributionFailure catch (e) {
      final already = e.code == ContributionError.alreadyReviewed.code;
      message = already ? l10n.reviewAlreadyReviewed : l10n.reviewFailed;
      close = already;
    } on NetworkFailure {
      message = l10n.reviewOffline;
      close = false;
    } on ZemaFailure {
      message = l10n.reviewFailed;
      close = false;
    }
    if (mounted) setState(() => _sending = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (close && mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final queue = ref.watch(reviewQueueProvider);
    final item = queue.value?.where((i) => i.id == widget.id).firstOrNull;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: queue.isLoading
              ? const CircularProgressIndicator()
              : Text(l10n.reviewAlreadyReviewed),
        ),
      );
    }
    final c = item.contribution;
    final current = item.currentSong;
    final song = c.song ?? current?.song;
    final timing = c.timing;
    final recording =
        c.recording ??
        current?.recordings
            .where((r) => r.id == timing?.recordingId)
            .firstOrNull;
    final details = [song?.artist, song?.album].nonNulls.join(' · ');
    final checks = [
      if (c.song != null) ...[
        l10n.reviewCheckLyrics,
        l10n.reviewCheckDetails,
        l10n.reviewCheckContent,
      ],
      if (c.recording != null) l10n.reviewCheckRecording,
      if (timing != null) l10n.reviewCheckTiming,
    ];
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: colors.muted,
          letterSpacing: 1,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(contributionKindName(l10n, item.kind))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZemaSpacing.screenSide,
          8,
          ZemaSpacing.screenSide,
          24,
        ),
        children: [
          Text(queuedTitle(item), style: textTheme.titleLarge),
          if (details.isNotEmpty)
            Text(
              details,
              style: textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          if (item.previousNote case final note?) ...[
            const SizedBox(height: 8),
            Text(l10n.reviewItemPreviousNote(note)),
          ],
          if (item.basedOnOlderVersion) ...[
            const SizedBox(height: 12),
            Text(
              l10n.reviewItemOlderVersion,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (c.kind == ContributionKind.editLyrics && current != null) ...[
            const SizedBox(height: 20),
            CorrectionChanges(
              base: current.song,
              edited: c.song!,
              recordings: current.recordings,
              timings: current.timings,
            ),
          ],
          if (recording != null) ...[
            heading(l10n.contributeReviewRecording),
            _RecordingSource(recording),
          ],
          if (song != null) ...[
            heading(l10n.contributeReviewLyrics),
            _Lyrics(song: song, starts: timing?.starts),
          ],
          heading(l10n.reviewItemChecklist),
          for (final (i, check) in checks.indexed)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked.contains(i),
              title: Text(check),
              onChanged: (on) => setState(
                () => on ?? false ? _checked.add(i) : _checked.remove(i),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            8,
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _sending
                    ? null
                    : () => _decide(item, ReviewDecision.reject),
                child: Text(l10n.reviewReject),
              ),
              OutlinedButton(
                onPressed: _sending
                    ? null
                    : () => _decide(item, ReviewDecision.requestChanges),
                child: Text(l10n.reviewRequestChanges),
              ),
              FilledButton(
                onPressed: _sending
                    ? null
                    : () => _decide(item, ReviewDecision.approve),
                child: Text(l10n.reviewApprove),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a recording is: a YouTube video (opened in YouTube) or a file.
class _RecordingSource extends ConsumerWidget {
  const _RecordingSource(this.recording);

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final duration = recording.duration;
    final details = [
      recording.artist,
      if (duration != null) formatDurationText(duration),
    ].nonNulls.join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recording.source == RecordingSource.youtube
              ? l10n.reviewItemYoutube
              : recording.fileName ?? '',
          style: textTheme.titleSmall,
        ),
        if (details.isNotEmpty)
          Text(
            details,
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        if (recording.youtubeId case final id?
            when recording.source == RecordingSource.youtube)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => unawaited(
                ref.read(openUrlProvider)(
                  Uri.https('www.youtube.com', '/watch', {'v': id}),
                ),
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.reviewItemOpenYoutube),
            ),
          ),
      ],
    );
  }
}

/// The lyrics; with [starts], a silent preview lights up each line at its
/// start.
class _Lyrics extends StatefulWidget {
  const _Lyrics({required this.song, this.starts});

  final Song song;
  final List<Duration>? starts;

  @override
  State<_Lyrics> createState() => _LyricsState();
}

class _LyricsState extends State<_Lyrics> {
  static const _tick = Duration(milliseconds: 100);

  Timer? _timer;
  var _position = Duration.zero;

  void _toggle() {
    if (_timer != null) return _stop();
    final end =
        (widget.starts?.lastOrNull ?? Duration.zero) +
        const Duration(seconds: 3);
    setState(() => _position = Duration.zero);
    _timer = Timer.periodic(_tick, (_) {
      if (_position >= end) return _stop();
      setState(() => _position += _tick);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final starts = widget.starts;
    final playing = _timer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (starts != null && starts.isNotEmpty)
          Row(
            children: [
              TextButton.icon(
                onPressed: _toggle,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label: Text(
                  playing ? l10n.reviewItemStop : l10n.reviewItemPreview,
                ),
              ),
              if (playing) Text(formatSyncTime(_position)),
            ],
          ),
        SongLines(
          song: widget.song,
          current: playing && starts != null ? lineAt(starts, _position) : null,
        ),
      ],
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title});

  final String title;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = _text.text.trim();
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: maxNoteLength,
        decoration: InputDecoration(hintText: l10n.reviewNoteHint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: note.isEmpty
              ? null
              : () => Navigator.of(context).pop(note),
          child: Text(l10n.reviewSend),
        ),
      ],
    );
  }
}
