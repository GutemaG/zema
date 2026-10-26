import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/data/app_settings.dart';
import '../application/player_providers.dart';
import '../data/sleep_timer.dart';

/// Opens C05, the sleep timer sheet.
Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SleepTimerSheet(),
  );
}

/// C05: 15 / 30 / 45 / 60 minutes, end of the current song, or a custom
/// number of minutes. While a timer runs, shows the time left and Cancel.
/// Picking an option starts it (replacing any running timer) and closes
/// the sheet. The default from Settings is shown selected, one tap away;
/// nothing starts until an option is tapped.
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  static const presets = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final timer = ref.watch(sleepTimerProvider);
    final preselected = ref.watch(
      settingsProvider.select((s) => s.sleepTimerDefault),
    );
    Widget? check(bool selected) =>
        selected ? Icon(Icons.check, color: colors.primaryText) : null;
    final player = ref.read(playerControllerProvider);
    final navigator = Navigator.of(context);

    void start(Duration after) {
      player.setSleepTimer(after);
      navigator.pop();
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(l10n.sleepTitle, style: textTheme.titleLarge),
              ),
            ),
            if (timer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.bedtime, color: colors.primaryText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: switch (timer) {
                        TimedSleep() => SleepCountdown(
                          timer: timer,
                          builder: (context, left) => Text(
                            l10n.sleepStopsIn(formatDuration(left)),
                            style: textTheme.bodyLarge,
                          ),
                        ),
                        EndOfTrackSleep() => Text(
                          l10n.sleepStopsAtEndOfSong,
                          style: textTheme.bodyLarge,
                        ),
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        player.cancelSleepTimer();
                        navigator.pop();
                      },
                      child: Text(l10n.sleepCancel),
                    ),
                  ],
                ),
              ),
            for (final minutes in presets)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                selected: preselected.minutes == minutes,
                trailing: check(preselected.minutes == minutes),
                title: Text(l10n.sleepMinutes(minutes)),
                onTap: () => start(Duration(minutes: minutes)),
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              selected: preselected == SleepTimerDefault.endOfSong,
              trailing: check(preselected == SleepTimerDefault.endOfSong),
              title: Text(l10n.sleepEndOfSong),
              onTap: () {
                player.sleepAtEndOfTrack();
                navigator.pop();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(l10n.sleepCustom),
              onTap: () async {
                final minutes = await showDialog<int>(
                  context: context,
                  builder: (_) => const CustomSleepDialog(),
                );
                if (minutes != null) start(Duration(minutes: minutes));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Asks for a number of minutes between [min] and [max]; Save stays
/// disabled, with a message, until the value is in range.
class CustomSleepDialog extends StatefulWidget {
  const CustomSleepDialog({super.key});

  static const min = 1;
  static const max = 180;

  @override
  State<CustomSleepDialog> createState() => _CustomSleepDialogState();
}

class _CustomSleepDialogState extends State<CustomSleepDialog> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  int? get _minutes {
    final value = int.tryParse(_field.text.trim());
    if (value == null ||
        value < CustomSleepDialog.min ||
        value > CustomSleepDialog.max) {
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _field,
      builder: (context, _) {
        final minutes = _minutes;
        final showError = _field.text.isNotEmpty && minutes == null;
        void save() => Navigator.of(context).pop(minutes);
        return AlertDialog(
          title: Text(l10n.sleepCustomTitle),
          content: TextField(
            controller: _field,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: minutes == null ? null : (_) => save(),
            decoration: InputDecoration(
              labelText: l10n.sleepCustomLabel,
              helperText: showError
                  ? null
                  : l10n.sleepCustomRange(
                      CustomSleepDialog.min,
                      CustomSleepDialog.max,
                    ),
              errorText: showError
                  ? l10n.sleepCustomRange(
                      CustomSleepDialog.min,
                      CustomSleepDialog.max,
                    )
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: minutes == null ? null : save,
              child: Text(l10n.actionSave),
            ),
          ],
        );
      },
    );
  }
}

/// Rebuilds once a second with the time left on [timer], rounded up to the
/// second (a new 30-minute timer reads 30:00, and 0:00 only at the end).
class SleepCountdown extends StatefulWidget {
  const SleepCountdown({super.key, required this.timer, required this.builder});

  final TimedSleep timer;
  final Widget Function(BuildContext context, Duration left) builder;

  @override
  State<SleepCountdown> createState() => _SleepCountdownState();
}

class _SleepCountdownState extends State<SleepCountdown> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.timer.remainingAt(clock.now());
    final seconds = (left.inMilliseconds / 1000).ceil();
    return widget.builder(context, Duration(seconds: seconds));
  }
}
