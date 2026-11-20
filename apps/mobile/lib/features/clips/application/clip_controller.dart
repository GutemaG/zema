import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../library/application/artwork_provider.dart';
import '../../library/application/song_info.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../../player/application/player_providers.dart';
import '../data/clip_encoder.dart';
import 'clip_look.dart';
import 'clip_timeline.dart';

final _log = Logger('clips');

final clipEncoderProvider = Provider<ClipEncoder>(
  (ref) => Platform.isAndroid
      ? AndroidClipEncoder()
      : const UnsupportedClipEncoder(),
);

/// Where clip frames and videos are made; emptied when the clip screen goes.
final clipFolderProvider = FutureProvider<Directory>(
  (ref) async =>
      Directory(p.join((await getTemporaryDirectory()).path, 'clips')),
);

/// A track's lyric lines for a clip, with their start times in the audio
/// (none for plain lyrics).
typedef ClipLyrics = ({List<String> texts, List<Duration> starts});

final clipLyricsProvider = FutureProvider.autoDispose.family<ClipLyrics, int>((
  ref,
  trackId,
) async {
  final lyrics = await ref.watch(trackLyricsProvider(trackId).future);
  if (lyrics == null) {
    return (texts: const <String>[], starts: const <Duration>[]);
  }
  final engine = lyrics.synced?.engine;
  final timed = engine != null && engine.lineCount == lyrics.lines.length;
  final shift = timed ? ref.watch(lyricsShiftProvider(lyrics)) : Duration.zero;
  return (
    texts: [for (final sung in lyrics.lines) sung.line.text],
    starts: timed
        ? [for (var i = 0; i < engine.lineCount; i++) engine.startOf(i) + shift]
        : const <Duration>[],
  );
});

enum ClipPhase { ready, making, done, failed }

class ClipState {
  const ClipState({
    this.track,
    this.start = Duration.zero,
    this.end = Duration.zero,
    this.preview,
    this.playing = false,
    this.phase = ClipPhase.ready,
    this.progress = 0,
    this.clip,
  });

  final Track? track;
  final Duration start;
  final Duration end;

  /// The frame at [start], or at the playing line while [playing], as PNG.
  final Uint8List? preview;

  /// Whether the selection is playing in the editor.
  final bool playing;
  final ClipPhase phase;

  /// 0 to 1 while [ClipPhase.making]: painting, then encoding.
  final double progress;
  final EncodedClip? clip;

  Duration get length => end - start;

  ClipState copyWith({
    Track? track,
    Duration? start,
    Duration? end,
    Uint8List? preview,
    bool? playing,
    ClipPhase? phase,
    double? progress,
    EncodedClip? clip,
    bool clearClip = false,
  }) => ClipState(
    track: track ?? this.track,
    start: start ?? this.start,
    end: end ?? this.end,
    preview: preview ?? this.preview,
    playing: playing ?? this.playing,
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    clip: clearClip ? null : clip ?? this.clip,
  );
}

/// The part of painting frames in the progress bar; encoding takes the rest.
const _paintShare = 0.25;

/// One clip of track `trackId`: its range, preview, making, sharing and
/// saving. Its files are deleted when the clip screen closes.
final clipControllerProvider = NotifierProvider.autoDispose
    .family<ClipController, ClipState, int>(ClipController.new);

class ClipController extends Notifier<ClipState> {
  ClipController(this.trackId);

  final int trackId;
  Directory? _folder;
  ClipScene? _scene;
  ClipLyrics? _lyrics;
  ClipLyricsLayout? _layout;
  ClipJob? _job;
  var _cancelled = false;
  AudioPlayer? _player;
  StreamSubscription<Duration>? _playing;
  int? _previewRow;
  var _painting = false;
  int? _wantedRow;

  @override
  ClipState build() {
    ref.onDispose(() {
      _cancelled = true;
      unawaited(_job?.cancel());
      unawaited(_playing?.cancel());
      unawaited(_player?.dispose());
      _scene?.dispose();
      final folder = _folder;
      if (folder != null && folder.existsSync()) {
        folder.deleteSync(recursive: true);
      }
    });
    unawaited(_load());
    return const ClipState();
  }

  /// The lyric line starts, for snapping the range.
  List<Duration> get lineStarts => _lyrics?.starts ?? const [];

  Future<void> _load() async {
    final found = await ref.read(databaseProvider).libraryDao.tracksByIds([
      trackId,
    ]);
    if (found.isEmpty || !ref.mounted) return;
    final track = found.single;
    final lyrics = await ref.read(clipLyricsProvider(trackId).future);
    _lyrics = lyrics;
    final playing = ref.read(currentTrackProvider)?.id == trackId;
    final range = defaultClipRange(
      lyrics.starts,
      track.duration,
      position: playing ? ref.read(positionProvider).value : null,
    );
    _layout = ClipLyricsLayout([
      '',
      if (lyrics.starts.isNotEmpty) ...lyrics.texts,
    ]);
    _scene = ClipScene(
      title: track.title,
      artist: track.artist,
      cover: await _cover(track),
    );
    if (!ref.mounted) return;
    state = state.copyWith(track: track, start: range.start, end: range.end);
    _showRowAt(range.start);
  }

  Future<ui.Image?> _cover(Track track) async {
    final picked = ref.read(coversProvider).value?[track.id];
    Uint8List? bytes;
    if (picked != null && File(picked).existsSync()) {
      bytes = await File(picked).readAsBytes();
    } else {
      bytes = await ref.read(artworkProvider(track.mediaStoreId).future);
    }
    return bytes == null ? null : decodeClipCover(bytes);
  }

  /// The layout row of the line sung at [t] in the audio: 0 before the first.
  int _rowAt(Duration t) {
    var row = 0;
    for (final (i, s) in lineStarts.indexed) {
      if (s > t) break;
      row = i + 1;
    }
    return row;
  }

  /// Repaints the preview for the line at [t], skipping rows passed while
  /// painting.
  void _showRowAt(Duration t) {
    final row = _rowAt(t);
    if (row == _previewRow && state.preview != null) return;
    _wantedRow = row;
    if (!_painting) unawaited(_paintPreview());
  }

  Future<void> _paintPreview() async {
    final scene = _scene;
    final layout = _layout;
    if (scene == null || layout == null) return;
    _painting = true;
    try {
      while (_wantedRow != null && _wantedRow != _previewRow) {
        final row = _wantedRow!;
        final preview = await paintClipPreview(scene, layout, row, scale: 0.5);
        if (!ref.mounted) return;
        _previewRow = row;
        state = state.copyWith(preview: preview);
      }
    } finally {
      _painting = false;
    }
  }

  /// Moves the selection, snapping the moved handle to a line start; the
  /// other gives way to keep it 5 s to 2 min, inside the track.
  void setRange(Duration start, Duration end) {
    final track = state.track;
    if (track == null || state.phase == ClipPhase.making) return;
    final movedStart = start != state.start;
    final range = clampClipRange(
      movedStart ? snapToLine(lineStarts, start) : start,
      movedStart ? end : snapToLine(lineStarts, end),
      track.duration,
      movedStart: movedStart,
    );
    if (range.start == state.start && range.end == state.end) return;
    unawaited(stop());
    state = state.copyWith(
      start: range.start,
      end: range.end,
      phase: ClipPhase.ready,
      clearClip: true,
    );
    _showRowAt(range.start);
  }

  /// Moves the start (or the end) to the next or previous line.
  void step({required bool start, required bool forward}) {
    final at = start ? state.start : state.end;
    final to = stepToLine(lineStarts, at, forward: forward);
    final track = state.track;
    if (track == null) return;
    final range = clampClipRange(
      start ? to : state.start,
      start ? state.end : to,
      track.duration,
      movedStart: start,
    );
    unawaited(stop());
    state = state.copyWith(
      start: range.start,
      end: range.end,
      phase: ClipPhase.ready,
      clearClip: true,
    );
    _showRowAt(range.start);
  }

  /// Plays the selection, pausing the main player, with the preview
  /// following the lines; again to stop.
  Future<void> togglePlay() async {
    if (state.playing) return stop();
    final track = state.track;
    if (track == null) return;
    await ref.read(audioHandlerProvider).pause();
    final player = _player ??= AudioPlayer();
    final start = state.start;
    try {
      await player.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.uri(Uri.parse(track.uri)),
          start: start,
          end: state.end,
        ),
      );
    } on Exception catch (e, s) {
      _log.warning('Could not play the clip', e, s);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(playing: true);
    await _playing?.cancel();
    _playing = player.positionStream.listen((p) => _showRowAt(start + p));
    unawaited(
      player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .then((_) => stop()),
    );
    unawaited(player.play());
  }

  Future<void> stop() async {
    await _playing?.cancel();
    _playing = null;
    await _player?.stop();
    if (!ref.mounted || !state.playing) return;
    state = state.copyWith(playing: false);
    _showRowAt(state.start);
  }

  /// The frames from [start] to [end]: when each starts and its layout row.
  List<({Duration at, int row})> _frames(Duration start, Duration end) => [
    for (final t in clipFrameTimes(lineStarts, start, end))
      (at: t.at, row: t.line == null ? 0 : t.line! + 1),
  ];

  /// Paints the frames and encodes the video.
  Future<void> make() async {
    final track = state.track;
    final scene = _scene;
    final layout = _layout;
    if (track == null ||
        scene == null ||
        layout == null ||
        state.phase == ClipPhase.making) {
      return;
    }
    await stop();
    _cancelled = false;
    state = state.copyWith(phase: ClipPhase.making, progress: 0);
    try {
      final root = await ref.read(clipFolderProvider.future);
      final old = _folder;
      if (old != null && old.existsSync()) old.deleteSync(recursive: true);
      final folder = _folder = Directory(
        p.join(root.path, '${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync(recursive: true);
      final background = File(p.join(folder.path, 'background.png'));
      await background.writeAsBytes(await scene.background());
      final planned = _frames(state.start, state.end);
      final frames = <ClipFrame>[];
      for (final (i, f) in planned.indexed) {
        if (_cancelled) throw const ClipCancelled();
        final file = File(p.join(folder.path, 'frame-$i.png'));
        await file.writeAsBytes(await paintClipLyrics(layout, f.row));
        frames.add(
          ClipFrame(
            file.path,
            f.at,
            scroll: i == 0 ? 0 : layout.scroll(planned[i - 1].row, f.row),
          ),
        );
        if (ref.mounted) {
          state = state.copyWith(
            progress: _paintShare * (i + 1) / planned.length,
          );
        }
      }
      if (_cancelled) throw const ClipCancelled();
      final job = _job = ref
          .read(clipEncoderProvider)
          .encode(
            ClipRequest(
              audioUri: track.uri,
              start: state.start,
              end: state.end,
              background: background.path,
              frames: frames,
              window: clipWindow,
              outPath: p.join(folder.path, 'zema-clip.mp4'),
            ),
          );
      final listening = job.progress.listen((f) {
        if (ref.mounted) {
          state = state.copyWith(progress: _paintShare + (1 - _paintShare) * f);
        }
      });
      try {
        final clip = await job.result;
        for (final f in frames) {
          File(f.path).deleteSync();
        }
        background.deleteSync();
        if (ref.mounted) {
          state = state.copyWith(
            phase: ClipPhase.done,
            progress: 1,
            clip: clip,
          );
        }
      } finally {
        _job = null;
        await listening.cancel();
      }
    } on ClipCancelled {
      if (ref.mounted) {
        state = state.copyWith(phase: ClipPhase.ready, progress: 0);
      }
    } on Exception catch (e, s) {
      _log.warning('Could not make a clip', e, s);
      if (ref.mounted) state = state.copyWith(phase: ClipPhase.failed);
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    await _job?.cancel();
  }

  /// The share text: the song's title and artist.
  String get shareText {
    final track = state.track;
    if (track == null) return '';
    final artist = track.artist;
    return artist == null || artist.isEmpty
        ? track.title
        : '${track.title} – $artist';
  }

  Future<bool> share() async {
    final clip = state.clip;
    if (clip == null) return false;
    return ref.read(clipEncoderProvider).share(clip.path, text: shareText);
  }

  Future<bool> save() async {
    final clip = state.clip;
    if (clip == null) return false;
    final name = shareText.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return ref
        .read(clipEncoderProvider)
        .saveToGallery(clip.path, name: '${name.isEmpty ? 'Zema' : name}.mp4');
  }
}
