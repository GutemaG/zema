/// A running sleep timer: playback stops when it ends.
sealed class SleepTimer {
  const SleepTimer();
}

/// Stops at [endsAt], fading out first.
class TimedSleep extends SleepTimer {
  const TimedSleep(this.endsAt);

  final DateTime endsAt;

  /// Time left at [now]; never negative.
  Duration remainingAt(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  bool operator ==(Object other) =>
      other is TimedSleep && other.endsAt == endsAt;

  @override
  int get hashCode => endsAt.hashCode;
}

/// Stops when the current song ends.
class EndOfTrackSleep extends SleepTimer {
  const EndOfTrackSleep();

  @override
  bool operator ==(Object other) => other is EndOfTrackSleep;

  @override
  int get hashCode => (EndOfTrackSleep).hashCode;
}
