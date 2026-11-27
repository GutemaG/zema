import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
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

/// Lets the user pick a photo for a clip; its path, or null.
final clipPicturePickerProvider = Provider<Future<String?> Function()>(
  (ref) =>
      () async => (await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 1440,
      ))?.path,
);

/// A track's lyric lines for a clip, with their transliterations and start
/// times in the audio (none for plain lyrics).
typedef ClipLyrics = ({
  List<String> texts,
  List<String?> translits,
  List<Duration> starts,
});

final clipLyricsProvider = FutureProvider.autoDispose.family<ClipLyrics, int>((
  ref,
  trackId,
) async {
  final lyrics = await ref.watch(trackLyricsProvider(trackId).future);
  if (lyrics == null) {
    return (
      texts: const <String>[],
      translits: const <String?>[],
      starts: const <Duration>[],
    );
  }
  final engine = lyrics.synced?.engine;
  final timed = engine != null && engine.lineCount == lyrics.lines.length;
  final shift = timed ? ref.watch(lyricsShiftProvider(lyrics)) : Duration.zero;
  return (
    texts: [for (final sung in lyrics.lines) sung.line.text],
    translits: [for (final sung in lyrics.lines) sung.line.transliteration],
    starts: timed
        ? [for (var i = 0; i < engine.lineCount; i++) engine.startOf(i) + shift]
        : const <Duration>[],
  );
});

enum ClipPhase { ready, making, done, failed }

/// The editor's preview: the background and the lyric layer, as half-size
/// PNGs, and the layer [from] which the lyrics move by [motion] (none: they
/// just show). [serial] changes with every new preview.
class ClipPreview {
  const ClipPreview({
    required this.background,
    required this.lyrics,
    required this.serial,
    this.from,
    this.scroll = 0,
    this.motion = ClipMotion.scroll,
    this.x = 0.5,
    this.focus = 0.5,
  });

  final Uint8List background;
  final Uint8List lyrics;
  final int serial;
  final Uint8List? from;

  /// How far [lyrics]' content sits below [from]'s, as a part of the height.
  final double scroll;
  final ClipMotion motion;

  /// Where the sung line sits, as a part of the width and of the height.
  final double x;
  final double focus;
}

class ClipState {
  const ClipState({
    this.track,
    this.start = Duration.zero,
    this.end = Duration.zero,
    this.look = const ClipLook(),
    this.preview,
    this.playing = false,
    this.picked = const [],
    this.withoutSong = false,
    this.phase = ClipPhase.ready,
    this.progress = 0,
    this.clip,
  });

  final Track? track;
  final Duration start;
  final Duration end;
  final ClipLook look;

  /// The frame at [start], or at the playing line while [playing].
  final ClipPreview? preview;

  /// Whether the selection is playing in the editor.
  final bool playing;

  /// For lyrics without timing: the lines shown, as indexes in order.
  final List<int> picked;

  /// Whether the video has silent audio instead of the recording.
  final bool withoutSong;
  final ClipPhase phase;

  /// 0 to 1 while [ClipPhase.making]: painting, then encoding.
  final double progress;
  final EncodedClip? clip;

  Duration get length => end - start;

  ClipState copyWith({
    Track? track,
    Duration? start,
    Duration? end,
    ClipLook? look,
    ClipPreview? preview,
    bool? playing,
    List<int>? picked,
    bool? withoutSong,
    ClipPhase? phase,
    double? progress,
    EncodedClip? clip,
    bool clearClip = false,
  }) => ClipState(
    track: track ?? this.track,
    start: start ?? this.start,
    end: end ?? this.end,
    look: look ?? this.look,
    preview: preview ?? this.preview,
    playing: playing ?? this.playing,
    picked: picked ?? this.picked,
    withoutSong: withoutSong ?? this.withoutSong,
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
  ui.Image? _coverImage;
  final _pictures = <String, ui.Image?>{};
  var _look = 0;
  ClipLyricsLayout? _layout;
  ClipJob? _job;
  var _cancelled = false;
  AudioPlayer? _player;
  StreamSubscription<Duration>? _playing;
  (int, int)? _shown;
  (int, int)? _wanted;
  final _retired = <ClipScene>[];
  var _painting = false;
  Uint8List? _back;
  var _backFor = -1;
  Uint8List? _shownLyrics;
  int? _demoFrom;
  var _playingAt = Duration.zero;

  @override
  ClipState build() {
    ref.listen(clipLyricsProvider(trackId), (_, _) {});
    ref.onDispose(() {
      _cancelled = true;
      unawaited(_job?.cancel());
      unawaited(_playing?.cancel());
      unawaited(_player?.dispose());
      _scene?.dispose();
      for (final scene in _retired) {
        scene.dispose();
      }
      _coverImage?.dispose();
      for (final image in _pictures.values) {
        image?.dispose();
      }
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

  /// Whether the lyrics have timing; without it the clip is a still page
  /// of [ClipState.picked] lines.
  bool get timed => lineStarts.isNotEmpty;

  /// The lyric lines, for picking when they have no timing.
  List<String> get lines => _lyrics?.texts ?? const [];

  /// The most lines a still page can show.
  static const maxPicked = 8;

  /// Shows or hides line [index] on the still page.
  Future<void> toggleLine(int index) async {
    if (timed || state.phase == ClipPhase.making) return;
    final picked = {...state.picked};
    if (!picked.remove(index)) {
      if (picked.length >= maxPicked) return;
      picked.add(index);
    }
    state = state.copyWith(
      picked: picked.toList()..sort(),
      phase: ClipPhase.ready,
      clearClip: true,
    );
    await _applyLook();
  }

  void setWithoutSong({required bool value}) {
    if (state.phase == ClipPhase.making) return;
    state = state.copyWith(
      withoutSong: value,
      phase: ClipPhase.ready,
      clearClip: true,
    );
  }

  /// Whether any timed line has a transliteration to show.
  bool get hasTransliteration =>
      lineStarts.isNotEmpty &&
      (_lyrics?.translits.any((t) => t?.trim().isNotEmpty ?? false) ?? false);

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
    _coverImage = await _cover(track);
    if (!ref.mounted) return;
    state = state.copyWith(
      track: track,
      start: range.start,
      end: range.end,
      picked: [
        for (final (i, t) in lyrics.texts.indexed)
          if (t.trim().isNotEmpty) i,
      ].take(4).toList(),
      look: ClipLook.fromPrefs(ref.read(sharedPreferencesProvider)),
    );
    await _applyLook();
  }

  /// Changes the look; the preview follows.
  Future<void> setLook(ClipLook look) async {
    if (state.track == null || state.phase == ClipPhase.making) return;
    final moved =
        look.motion != state.look.motion ||
        look.position != state.look.position;
    state = state.copyWith(look: look, phase: ClipPhase.ready, clearClip: true);
    await _applyLook(demo: moved && !state.playing);
  }

  /// A gallery photo for the look, or null if none was picked.
  Future<String?> pickPicture() => ref.read(clipPicturePickerProvider)();

  /// Rebuilds the scene and layout for the current look and repaints.
  Future<void> _applyLook({bool demo = false}) async {
    final track = state.track;
    final lyrics = _lyrics;
    if (track == null || lyrics == null) return;
    final generation = ++_look;
    final look = state.look;
    final photo = await _picture(look.photo, width: 1080);
    final album = await _picture(look.albumPicture);
    final artist = await _picture(look.artistPicture);
    if (!ref.mounted || generation != _look) return;
    _layout = timed
        ? ClipLyricsLayout(
            ['', ...lyrics.texts],
            translits: [null, ...lyrics.translits],
            look: look,
          )
        : ClipLyricsLayout(
            state.picked.isEmpty
                ? ['']
                : [for (final i in state.picked) lyrics.texts[i]],
            translits: [for (final i in state.picked) lyrics.translits[i]],
            look: look,
          );
    final old = _scene;
    _back = null;
    _scene = ClipScene(
      title: look.title ?? track.title,
      artist: look.artist ?? track.artist,
      album: look.album ?? track.album,
      cover: _coverImage,
      photo: photo,
      albumPicture: album,
      artistPicture: artist,
      look: look,
    );
    if (old != null) {
      _painting ? _retired.add(old) : old.dispose();
    }
    _showRowAt(state.playing ? _playingAt : state.start, demo: demo);
  }

  /// Shows the look's line change once in the preview.
  void replayMotion() {
    if (state.phase == ClipPhase.making || state.playing) return;
    _showRowAt(state.start, demo: true);
  }

  /// A picked photo, decoded once per path.
  Future<ui.Image?> _picture(String? path, {int width = 480}) async {
    if (path == null) return null;
    if (_pictures.containsKey(path)) return _pictures[path];
    final file = File(path);
    final image = file.existsSync()
        ? await decodeClipCover(await file.readAsBytes(), width: width)
        : null;
    _pictures[path] = image;
    return image;
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
    if (!timed) return ClipLyricsLayout.page;
    var row = 0;
    for (final (i, s) in lineStarts.indexed) {
      if (s > t) break;
      row = i + 1;
    }
    return row;
  }

  /// Repaints the preview for the line at [t], skipping rows passed while
  /// painting. With [demo], it moves there from the line before (the first
  /// line from the start's dots) to show the look's motion.
  void _showRowAt(Duration t, {bool demo = false}) {
    var row = _rowAt(t);
    if (demo && timed) {
      if (row == 0) row = 1;
      _demoFrom = row - 1;
      _shown = null;
    }
    final wanted = (row, _look);
    if (wanted == _shown && state.preview != null) return;
    _wanted = wanted;
    if (!_painting) unawaited(_paintPreview());
  }

  Future<void> _paintPreview() async {
    _painting = true;
    try {
      while (_wanted != null && _wanted != _shown) {
        final scene = _scene;
        final layout = _layout;
        if (scene == null || layout == null) return;
        final wanted = _wanted!;
        final shown = _shown;
        final demo = _demoFrom;
        _demoFrom = null;
        if (_back == null || _backFor != wanted.$2) {
          _back = await paintClipBackground(scene, scale: 0.5);
          _backFor = wanted.$2;
        }
        final background = _back!;
        final lyrics = await paintClipLyrics(layout, wanted.$1, scale: 0.5);
        Uint8List? from;
        var scroll = 0.0;
        if (demo != null) {
          from = await paintClipLyrics(layout, demo, scale: 0.5);
          scroll = layout.scroll(demo, wanted.$1);
        } else if (state.playing &&
            shown != null &&
            shown.$2 == wanted.$2 &&
            shown.$1 >= 0 &&
            wanted.$1 >= 0) {
          from = _shownLyrics;
          scroll = layout.scroll(shown.$1, wanted.$1);
        }
        if (!ref.mounted) return;
        _shown = wanted;
        _shownLyrics = lyrics;
        state = state.copyWith(
          preview: ClipPreview(
            background: background,
            lyrics: lyrics,
            serial: (state.preview?.serial ?? 0) + 1,
            from: from,
            scroll: scroll,
            motion: layout.look.motion,
            x: layout.look.position.x,
            focus: layout.look.position.focus,
          ),
        );
      }
    } finally {
      _painting = false;
      for (final scene in _retired) {
        scene.dispose();
      }
      _retired.clear();
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
    _playing = player.positionStream.listen((p) {
      _playingAt = start + p;
      _showRowAt(_playingAt);
    });
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
    if (!timed)
      (at: Duration.zero, row: ClipLyricsLayout.page)
    else
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
              audioUri: state.withoutSong ? null : track.uri,
              start: state.start,
              end: state.end,
              background: background.path,
              frames: frames,
              window: clipWindow,
              motion: layout.look.motion,
              centerX: layout.look.position.x,
              center: layout.look.position.focus,
              transition: clipTransition(layout.look.motion),
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
        unawaited(state.look.save(ref.read(sharedPreferencesProvider)));
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
