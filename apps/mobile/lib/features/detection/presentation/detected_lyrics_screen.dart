import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../lyrics/application/lyrics_prefs.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../application/detected_song.dart';
import '../application/detection_settings.dart';
import '../application/lyrics_overlay_sync.dart';

class DetectedLyricsScreen extends ConsumerStatefulWidget {
  const DetectedLyricsScreen({super.key});

  @override
  ConsumerState<DetectedLyricsScreen> createState() =>
      _DetectedLyricsScreenState();
}

class _DetectedLyricsScreenState extends ConsumerState<DetectedLyricsScreen> {
  DetectedMatch? _match;
  Timer? _ticker;
  int? _current;

  @override
  void initState() {
    super.initState();
    if (ref.read(detectedSongProvider) case final DetectedMatch match) {
      _match = match;
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    _tick();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final match = _match;
    if (match == null || !mounted) return;
    final lyrics = ref.read(detectedLyricsProvider(match.song.id)).value;
    int? current;
    if (lyrics != null) {
      final position = match.positionAt(clock.now()) - lyrics.recordingOffset;
      for (final (i, line) in lyrics.lines.indexed) {
        final at = line.at;
        if (at == null || at > position) break;
        current = i;
      }
    }
    if (current != _current) setState(() => _current = current);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    ref.listen(detectedSongProvider, (_, next) {
      if (next is DetectedMatch) setState(() => _match = next);
    });
    final match = _match;
    if (match == null) return Scaffold(appBar: AppBar());
    final app = DetectionApp.labelOf(match.playback.source);
    final live = ref.watch(detectedSongProvider)?.key == match.key;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.detectedLyricsFrom(app),
              style: text.bodySmall?.copyWith(color: colors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (ref.watch(detectedLyricsProvider(match.song.id))) {
                AsyncData(value: final lyrics?) when lyrics.sung.isNotEmpty =>
                  LyricsLines(
                    lines: lyrics.sung,
                    synced: lyrics.lines.any((line) => line.at != null),
                    focus: true,
                    current: live ? _current : null,
                    display: ref.watch(lyricsDisplayProvider),
                  ),
                AsyncError(:final error) => LyricsUnavailable(error: error),
                AsyncData() => Center(
                  child: Text(
                    l10n.playerNoLyrics,
                    style: text.bodyMedium?.copyWith(color: colors.muted),
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            if (!live)
              Padding(
                padding: const EdgeInsets.all(ZemaSpacing.screenSide),
                child: Text(
                  l10n.detectedLyricsStopped(app),
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
