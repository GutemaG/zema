import 'package:zema_core/zema_core.dart';

/// Everything the UI needs about the player except the position, which
/// changes too often and has its own stream.
class PlayerSnapshot {
  const PlayerSnapshot({
    this.queue = const [],
    this.index = -1,
    this.playing = false,
    this.buffering = false,
    this.shuffle = false,
    this.repeat = QueueRepeat.off,
    this.duration,
  });

  static const empty = PlayerSnapshot();

  /// Tracks in play order.
  final List<Track> queue;

  /// Index of the current track in [queue], or -1.
  final int index;
  final bool playing;

  /// Loading or buffering the current track.
  final bool buffering;
  final bool shuffle;
  final QueueRepeat repeat;

  /// Duration of the current track once known.
  final Duration? duration;

  Track? get current =>
      index < 0 || index >= queue.length ? null : queue[index];
  bool get hasTrack => current != null;
}
