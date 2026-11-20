import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lyrics/application/lyrics_prefs.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/lyrics_overlay.dart';
import 'lyrics_overlay_sync.dart';

/// The overlay source of songs played in Zema itself.
const playerOverlaySource = 'zema';

const _playerKey = 'player:';

/// The overlay key of track [trackId] played in Zema.
String playerOverlayKey(int trackId) => '$_playerKey$trackId';

/// The track of a [playerOverlayKey], or null for another key.
int? playerOverlayTrack(String key) => key.startsWith(_playerKey)
    ? int.tryParse(key.substring(_playerKey.length))
    : null;

/// The current track's lyrics as a floating sheet, and whether it's playing;
/// null when nothing with lyrics is current.
typedef PlayerOverlay = ({OverlaySheet sheet, bool playing});

final playerOverlayProvider = Provider<PlayerOverlay?>((ref) {
  final track = ref.watch(currentTrackProvider);
  if (track == null) return null;
  final lyrics = ref.watch(trackLyricsProvider(track.id)).value;
  if (lyrics == null || lyrics.lines.isEmpty) return null;
  final engine = lyrics.synced?.engine;
  final timed = engine != null && engine.lineCount == lyrics.lines.length;
  return (
    sheet: OverlaySheet(
      key: playerOverlayKey(track.id),
      source: playerOverlaySource,
      songId: lyrics.song.id,
      title: lyrics.song.title,
      artist: track.artist ?? lyrics.song.artist,
      lines: [
        for (final (i, sung) in lyrics.lines.indexed)
          OverlayLine(sung.line.text, at: timed ? engine.startOf(i) : null),
      ],
      offset: timed ? -ref.watch(lyricsShiftProvider(lyrics)) : Duration.zero,
    ),
    playing:
        ref.watch(playerStateProvider.select((s) => s.value?.playing)) ?? false,
  );
});

/// Whether the floating sheet [key] of a song played in Zema shows: as the
/// user last chose for it, or as Settings says.
bool playerOverlayWanted(Ref ref, String key) =>
    ref.read(overlayChoicesProvider)[key] ??
    ref.read(settingsProvider).floatLyrics;

/// Keeps the user's timing change [offset] from the floating sheet of track
/// [trackId], as the lyrics view does.
Future<void> savePlayerOverlayOffset(
  Ref ref,
  int trackId,
  Duration offset,
) async {
  final lyrics = ref.read(trackLyricsProvider(trackId)).value;
  final recording = lyrics?.recording;
  if (lyrics == null || recording == null) return;
  await ref
      .read(lyricsOffsetProvider(recording.id).notifier)
      .set(-offset - recording.offset - lyrics.soundOffset);
}

/// How far the overlay's clock may drift from the player before it's sent
/// again.
const playerOverlayDrift = Duration(milliseconds: 700);

/// Sends the player's position to the floating sheet when it plays, pauses,
/// seeks or changes track (the sheet runs its own clock in between).
final playerOverlayClockProvider = Provider<void>((ref) {
  final overlay = ref.watch(lyricsOverlayProvider);
  ({bool playing, Duration position, DateTime at, int? track})? sent;

  void send(Duration position) {
    final state = ref.read(playerStateProvider).value;
    final track = state?.current?.id;
    final playing = state?.playing ?? false;
    final now = clock.now();
    if (sent case final last?
        when last.playing == playing && last.track == track) {
      final expected = playing
          ? last.position + now.difference(last.at)
          : last.position;
      if ((position - expected).abs() < playerOverlayDrift) return;
    }
    sent = (playing: playing, position: position, at: now, track: track);
    unawaited(
      overlay.setClock(
        playerOverlaySource,
        playing: playing,
        position: position,
        at: now,
        duration: state?.duration,
      ),
    );
  }

  Duration position() => ref.read(positionProvider).value ?? Duration.zero;

  ref.listen(positionProvider, (_, next) {
    if (next.value case final value?) send(value);
  });
  ref.listen(playerStateProvider, (_, _) => send(position()));
  ref.listen(playerOverlayProvider.select((o) => o?.sheet.key), (_, _) {
    sent = null;
    send(position());
  }, fireImmediately: true);
});
