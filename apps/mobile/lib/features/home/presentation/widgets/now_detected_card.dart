import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../detection/application/detected_song.dart';
import '../../../detection/application/detection_providers.dart';
import '../../../detection/application/detection_settings.dart';
import '../../../detection/application/lyrics_overlay_sync.dart';
import '../../../detection/data/playback_detector.dart';
import '../../../detection/presentation/choose_detected_song_sheet.dart';
import 'home_section_header.dart';

class NowDetectedCard extends ConsumerWidget {
  const NowDetectedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detected = ref.watch(detectedSongProvider);
    if (detected is! DetectedMatch && detected is! DetectedUnsure) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    final app = DetectionApp.labelOf(detected!.playback.source);
    final shape = BorderRadius.circular(ZemaRadius.small);

    Future<void> float() async {
      final messenger = ScaffoldMessenger.of(context);
      final overlay = ref.read(lyricsOverlayProvider);
      if (!await overlay.canShow()) {
        await overlay.openSettings();
        return;
      }
      ref.read(overlayChoicesProvider.notifier).open(detected.key);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.homeFloatingLater(app))));
    }

    void open() => unawaited(context.push<void>(AppRoutes.detectedLyrics));

    final (title, artist) = switch (detected) {
      DetectedMatch(:final song) => (song.title, song.artist),
      _ => (detected.playback.title ?? '', detected.playback.artist),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(title: l10n.homeNowDetected),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
          ),
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: shape,
              side: BorderSide(color: colors.line),
            ),
            child: InkWell(
              borderRadius: shape,
              onTap: detected is DetectedMatch ? open : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Badge(label: app),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyLarge?.copyWith(color: colors.text),
                          ),
                          if (artist != null)
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Progress(playback: detected.playback),
                    const SizedBox(height: 8),
                    switch (detected) {
                      DetectedUnsure(:final candidates) => _Ask(
                        title: candidates.first.title,
                        onYes: () => unawaited(
                          ref
                              .read(detectedMatchControllerProvider)
                              .confirm(detected.playback, candidates.first),
                        ),
                        onChoose: () => unawaited(
                          showChooseDetectedSongSheet(context, detected),
                        ),
                      ),
                      _ => Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (ref.watch(otherAppsSupportedProvider))
                            OutlinedButton.icon(
                              onPressed: () => unawaited(float()),
                              icon: const Icon(
                                Icons.picture_in_picture_alt_outlined,
                              ),
                              label: Text(l10n.homeShowFloating),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: open,
                            icon: const Icon(Icons.lyrics_outlined),
                            label: Text(l10n.homeOpenLyrics),
                          ),
                        ],
                      ),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ZemaRadius.small),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.accentText),
      ),
    );
  }
}

class _Ask extends StatelessWidget {
  const _Ask({
    required this.title,
    required this.onYes,
    required this.onChoose,
  });

  final String title;
  final VoidCallback onYes;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeDetectedAsk(title),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.text),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: onYes,
              child: Text(l10n.homeDetectedYes),
            ),
            TextButton(
              onPressed: onChoose,
              child: Text(l10n.homeDetectedChoose),
            ),
          ],
        ),
      ],
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress({required this.playback});

  final DetectedPlayback playback;

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_Progress old) {
    super.didUpdateWidget(old);
    _restart();
  }

  void _restart() {
    _ticker?.cancel();
    _ticker = widget.playback.isPlaying
        ? Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}))
        : null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.playback.duration;
    if (duration == null) return const SizedBox.shrink();
    final position = widget.playback.positionAt(clock.now());
    final colors = context.zemaColors;
    return LinearProgressIndicator(
      value: position.inMilliseconds / duration.inMilliseconds,
      color: colors.primary,
      backgroundColor: colors.line,
      minHeight: 3,
      borderRadius: BorderRadius.circular(2),
    );
  }
}
