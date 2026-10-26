import 'package:clock/clock.dart';
import 'package:zema_core/zema_core.dart';

/// Decides when a play counts: after [threshold] of actual playing, or the
/// whole track when it is shorter. Time paused, loading or skipped by
/// seeking doesn't count, and each play counts at most once, however often
/// the listener seeks back.
///
/// The player tells it when a play starts ([start]), when sound is coming
/// out ([setPlaying]), on every position update while playing ([tick]) and
/// when a track ends ([completed]). It keeps no timer of its own: the
/// position updates are frequent enough, and nothing is left running when
/// playback stops.
class PlayCounter {
  PlayCounter({required this.onCounted});

  static const threshold = Duration(seconds: 30);

  final void Function(Track track) onCounted;

  Track? _track;
  var _counted = false;
  var _listened = Duration.zero;

  /// When the current stretch of playing started, or null while not
  /// playing.
  DateTime? _since;

  /// Starts a new play of [track]: a new queue entry, or the same song
  /// again (repeat one). Keeps the current playing state.
  void start(Track track) {
    _track = track;
    _counted = false;
    _listened = Duration.zero;
    if (_since != null) _since = clock.now();
  }

  /// Whether sound is coming out right now.
  void setPlaying(bool playing) {
    if (playing == (_since != null)) return;
    if (playing) {
      _since = clock.now();
    } else {
      _check();
      _since = null;
    }
  }

  /// A position update: counts the play once enough has been heard.
  void tick() => _check();

  /// The track played to its end. Counts a song shorter than [threshold]
  /// that hasn't counted yet (the last position update can come a little
  /// before the end).
  void completed() {
    _check();
    final track = _track;
    if (track == null || _counted || track.duration >= threshold) return;
    _count();
  }

  /// Ends the current play without counting it.
  void stop() {
    _track = null;
    _since = null;
  }

  void _check() {
    final track = _track;
    final since = _since;
    if (track == null || _counted || since == null) return;
    final now = clock.now();
    _listened += now.difference(since);
    _since = now;
    final duration = track.duration;
    final target = duration > Duration.zero && duration < threshold
        ? duration
        : threshold;
    if (_listened >= target) _count();
  }

  void _count() {
    _counted = true;
    onCounted(_track!);
  }
}
