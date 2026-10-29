import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/reports_dao.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/application/report_sender.dart';

/// Opens Report wrong lyrics for song [songId] and, when known, the
/// [recordingId] whose lyrics are shown. The answer shows in a snackbar.
Future<void> showReportLyricsSheet(
  BuildContext context, {
  required String songId,
  String? recordingId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ReportLyricsSheet(songId: songId, recordingId: recordingId),
  );
}

/// A reason, an optional note and Send.
class ReportLyricsSheet extends ConsumerStatefulWidget {
  const ReportLyricsSheet({super.key, required this.songId, this.recordingId});

  /// The longest note the catalog accepts.
  static const maxNoteLength = 500;

  final String songId;
  final String? recordingId;

  @override
  ConsumerState<ReportLyricsSheet> createState() => _ReportLyricsSheetState();
}

class _ReportLyricsSheetState extends ConsumerState<ReportLyricsSheet> {
  final _note = TextEditingController();
  ReportReason? _reason;
  var _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(ReportReason reason) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    final note = _note.text.trim();
    final outcome = await ref
        .read(reportSenderProvider)
        .send(
          LyricsReport(
            songId: widget.songId,
            recordingId: widget.recordingId,
            reason: reason,
            note: note.isEmpty ? null : note,
          ),
        );
    if (!mounted) return;
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            ReportOutcome.sent => l10n.reportSent,
            ReportOutcome.queued => l10n.reportQueued,
            ReportOutcome.limited => l10n.reportLimited,
            ReportOutcome.failed => l10n.reportFailed,
          }),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final reason = _reason;
    return Padding(
      // Keeps the note and Send above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZemaSpacing.screenSide,
                  0,
                  ZemaSpacing.screenSide,
                  4,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.reportLyrics,
                    style: textTheme.titleMedium?.copyWith(color: colors.text),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                ),
                child: Text(
                  l10n.reportReasonPrompt,
                  style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
              ),
              RadioGroup<ReportReason>(
                groupValue: reason,
                onChanged: (value) {
                  if (!_sending) setState(() => _reason = value);
                },
                child: Column(
                  children: [
                    for (final (value, label) in [
                      (ReportReason.wrongWords, l10n.reportReasonWrongWords),
                      (ReportReason.wrongTiming, l10n.reportReasonWrongTiming),
                      (ReportReason.wrongSong, l10n.reportReasonWrongSong),
                      (ReportReason.other, l10n.reportReasonOther),
                    ])
                      RadioListTile<ReportReason>(
                        value: value,
                        title: Text(label),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                ),
                child: TextField(
                  controller: _note,
                  enabled: !_sending,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: ReportLyricsSheet.maxNoteLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  decoration: InputDecoration(labelText: l10n.reportNote),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZemaSpacing.screenSide,
                  8,
                  ZemaSpacing.screenSide,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _sending
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.actionCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: reason == null || _sending
                          ? null
                          : () => unawaited(_send(reason)),
                      child: _sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.reportSend),
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
