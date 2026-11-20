import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../lyrics/application/lyrics_prefs.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../../player/application/player_providers.dart';
import '../application/keep_listening.dart';
import '../application/listen_controller.dart';
import 'keep_listening_bar.dart';

ProviderListenable<AsyncValue<TrackLyrics?>> foundLyricsProvider(
  ListenFound found,
) => switch (found.track) {
  final track? => trackLyricsProvider(track.id),
  null => matchedSongLyricsProvider((found.song!.id, found.match.recordingId)),
};

/// Plays a library match from where it is now; a catalog match has no file.
Future<void> playMatch(WidgetRef ref, ListenFound found) async {
  final track = found.track;
  if (track == null) return;
  final player = ref.read(playerControllerProvider);
  await player.playList([track], position: found.playFrom(clock.now()));
  final now = found.playFrom(clock.now());
  if (now > Duration.zero) await player.seek(now);
}

class ListenLyricsScreen extends ConsumerStatefulWidget {
  const ListenLyricsScreen({super.key});

  @override
  ConsumerState<ListenLyricsScreen> createState() => _ListenLyricsScreenState();
}

class _ListenLyricsScreenState extends ConsumerState<ListenLyricsScreen> {
  ListenFound? _found;
  Timer? _ticker;
  int? _current;
  var _ended = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(listenControllerProvider);
    if (state is ListenFound) _found = state;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    _tick();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final found = _found;
    if (found == null || !mounted) return;
    final now = clock.now();
    final ended = found.endedAt(now);
    final lyrics = ref.read(foundLyricsProvider(found)).value;
    final synced = lyrics?.synced;
    final current = lyrics == null || synced == null
        ? null
        : synced.engine
              .at(
                found.positionAt(now),
                offset: ref.read(lyricsShiftProvider(lyrics)),
              )
              .current;
    if (current != _current || ended != _ended) {
      setState(() {
        _current = current;
        _ended = ended;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(listenControllerProvider);
    ref.listen(listenControllerProvider, (previous, next) {
      if (next is ListenFound) {
        setState(() {
          _found = next;
          _current = null;
        });
        _tick();
      } else if (previous is Listening &&
          (next is ListenNotFound || next is ListenFailed)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.listenResyncFailed)));
      }
    });
    final found = _found;
    if (found == null) {
      return Scaffold(appBar: AppBar());
    }
    final track = found.track;
    final busy = state is Listening || state is ListenLoading;
    final controller = ref.read(listenControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(found.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (found.artist case final artist?)
              Text(
                artist,
                style: text.bodySmall?.copyWith(color: colors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (track != null)
            IconButton(
              tooltip: l10n.listenPlayFromHere,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () async {
                await playMatch(ref, found);
                if (context.mounted) {
                  context.pushReplacement(AppRoutes.nowPlaying);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (ref.watch(foundLyricsProvider(found))) {
                AsyncData(value: final lyrics?) when lyrics.lines.isNotEmpty =>
                  LyricsLines(
                    lines: lyrics.lines,
                    synced: lyrics.synced != null,
                    focus: true,
                    current: _current,
                    display: ref.watch(lyricsDisplayProvider),
                  ),
                AsyncData() when track != null => NoLyrics(track: track),
                AsyncData() => Center(
                  child: Text(
                    l10n.playerNoLyrics,
                    style: text.bodyLarge?.copyWith(color: colors.muted),
                  ),
                ),
                AsyncError(:final error) => LyricsUnavailable(error: error),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            if (_ended || !found.sure)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZemaSpacing.screenSide,
                  8,
                  ZemaSpacing.screenSide,
                  0,
                ),
                child: Text(
                  _ended ? l10n.listenSongEnded : l10n.listenUnsure,
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            if (ref.watch(keepListeningProvider).on)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                  vertical: 8,
                ),
                child: KeepListeningBar(),
              )
            else
              Padding(
                padding: const EdgeInsets.all(ZemaSpacing.screenSide),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? controller.cancel : controller.listen,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_ended ? Icons.mic_rounded : Icons.sync_rounded),
                    label: Text(
                      busy
                          ? l10n.listenListening
                          : _ended
                          ? l10n.listenAgain
                          : l10n.listenResync,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
