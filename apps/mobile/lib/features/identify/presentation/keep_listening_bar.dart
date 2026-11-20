import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/keep_listening.dart';

KeepListeningTexts keepListeningTexts(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final material = MaterialLocalizations.of(context);
  final always = MediaQuery.alwaysUse24HourFormatOf(context);
  return KeepListeningTexts(
    waiting: l10n.keepListeningWaiting,
    until: (until) => l10n.keepListeningUntil(
      material.formatTimeOfDay(
        TimeOfDay.fromDateTime(until),
        alwaysUse24HourFormat: always,
      ),
    ),
    stop: l10n.keepListeningStop,
    timeUp: l10n.keepListeningTimeUp,
    microphone: l10n.keepListeningMicrophone,
  );
}

/// Asks how long, then starts Keep listening.
Future<void> showKeepListeningSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final texts = keepListeningTexts(context);
  final length = await showModalBottomSheet<Duration>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.keepListening,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              Platform.isAndroid
                  ? l10n.keepListeningAbout
                  : l10n.keepListeningAboutOpen,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.zemaColors.muted),
            ),
          ),
          for (final length in keepListeningLengths)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.timer_outlined),
              title: Text(
                length.inMinutes < 60
                    ? l10n.keepListeningMinutes(length.inMinutes)
                    : l10n.keepListeningHours(length.inHours),
              ),
              onTap: () => Navigator.of(context).pop(length),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (length == null) return;
  await ref.read(keepListeningProvider.notifier).start(length, texts);
}

/// Keep listening's button, or while it's on, until when with Stop.
class KeepListeningBar extends ConsumerWidget {
  const KeepListeningBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    final keep = ref.watch(keepListeningProvider);
    if (keep.until case final until?) {
      final time = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(until),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.graphic_eq_rounded, size: 18, color: colors.muted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.keepListeningOn(time),
              style: text.bodyMedium?.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: ref.read(keepListeningProvider.notifier).stop,
            child: Text(l10n.keepListeningStop),
          ),
        ],
      );
    }
    final why = switch (keep.ended) {
      KeepListeningEnd.timeUp => l10n.keepListeningTimeUp,
      KeepListeningEnd.microphone => l10n.keepListeningMicrophone,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => unawaited(showKeepListeningSheet(context, ref)),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.text,
            side: BorderSide(color: colors.line),
          ),
          icon: const Icon(Icons.all_inclusive_rounded),
          label: Text(l10n.keepListening),
        ),
        if (why != null) ...[
          const SizedBox(height: 6),
          Text(
            why,
            style: text.bodySmall?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
