import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../application/clip_controller.dart';

/// Share clip: pick the part of the song (handles snap to lines, Play to
/// hear it with the preview following), then Make video, Share and Save.
class ClipScreen extends ConsumerWidget {
  const ClipScreen({super.key, required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = trackId;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clipTitle)),
      body: id == null ? const SizedBox.shrink() : _Body(trackId: id),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final clip = ref.watch(clipControllerProvider(trackId));
    final controller = ref.read(clipControllerProvider(trackId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    final preview = clip.preview;

    void notify(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    final making = clip.phase == ClipPhase.making;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZemaSpacing.screenSide),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: preview == null
                        ? ColoredBox(
                            color: colors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Semantics(
                                image: true,
                                label: l10n.clipPreview,
                                child: Image.memory(
                                  preview,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                              if (!making)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: IconButton.filled(
                                      tooltip: clip.playing
                                          ? l10n.clipStop
                                          : l10n.clipPlay,
                                      icon: Icon(
                                        clip.playing
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                      ),
                                      onPressed: () =>
                                          unawaited(controller.togglePlay()),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (clip.track case final track?) ...[
              Row(
                children: [
                  _Step(
                    icon: Icons.chevron_left,
                    tooltip: l10n.clipStartEarlier,
                    onPressed: making
                        ? null
                        : () => controller.step(start: true, forward: false),
                  ),
                  _Step(
                    icon: Icons.chevron_right,
                    tooltip: l10n.clipStartLater,
                    onPressed: making
                        ? null
                        : () => controller.step(start: true, forward: true),
                  ),
                  Expanded(
                    child: Text(
                      l10n.clipRange(
                        formatDuration(clip.start),
                        formatDuration(clip.end),
                        clip.length.inSeconds,
                      ),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ),
                  _Step(
                    icon: Icons.chevron_left,
                    tooltip: l10n.clipEndEarlier,
                    onPressed: making
                        ? null
                        : () => controller.step(start: false, forward: false),
                  ),
                  _Step(
                    icon: Icons.chevron_right,
                    tooltip: l10n.clipEndLater,
                    onPressed: making
                        ? null
                        : () => controller.step(start: false, forward: true),
                  ),
                ],
              ),
              if (track.duration > Duration.zero)
                RangeSlider(
                  min: 0,
                  max: track.duration.inMilliseconds.toDouble(),
                  values: RangeValues(
                    clip.start.inMilliseconds.toDouble(),
                    clip.end.inMilliseconds
                        .clamp(0, track.duration.inMilliseconds)
                        .toDouble(),
                  ),
                  semanticFormatterCallback: (v) =>
                      formatDuration(Duration(milliseconds: v.round())),
                  onChanged: making
                      ? null
                      : (v) => controller.setRange(
                          Duration(milliseconds: v.start.round()),
                          Duration(milliseconds: v.end.round()),
                        ),
                ),
            ],
            const SizedBox(height: 4),
            if (making) ...[
              LinearProgressIndicator(value: clip.progress),
              const SizedBox(height: 8),
              Text(
                l10n.clipMaking((clip.progress * 100).floor()),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => unawaited(controller.cancel()),
                child: Text(l10n.actionCancel),
              ),
            ] else if (clip.phase == ClipPhase.done) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined),
                      label: Text(l10n.clipSave),
                      onPressed: () async {
                        final saved = await controller.save();
                        notify(saved ? l10n.clipSaved : l10n.clipSaveFailed);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.clipShare),
                      onPressed: () async {
                        if (!await controller.share()) {
                          notify(l10n.clipShareFailed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (clip.phase == ClipPhase.failed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.clipFailed,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.accentText,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.movie_outlined),
                  label: Text(l10n.clipMake),
                  onPressed: preview == null
                      ? null
                      : () => unawaited(controller.make()),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.clipCopyright,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.faint),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}
