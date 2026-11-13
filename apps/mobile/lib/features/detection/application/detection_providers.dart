import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../data/playback_detector.dart';

final _log = Logger('detection');

final playbackDetectorProvider = Provider<PlaybackDetector>(
  (ref) => Platform.isAndroid
      ? const AndroidPlaybackDetector()
      : const NoPlaybackDetector(),
);

final otherAppsSupportedProvider = Provider<bool>((ref) => Platform.isAndroid);

final detectionAccessProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(playbackDetectorProvider).hasAccess(),
);

final detectedPlaybacksProvider =
    NotifierProvider<DetectedPlaybacks, Map<String, DetectedPlayback>>(
      DetectedPlaybacks.new,
    );

class DetectedPlaybacks extends Notifier<Map<String, DetectedPlayback>> {
  @override
  Map<String, DetectedPlayback> build() {
    final subscription = ref
        .watch(playbackDetectorProvider)
        .events
        .listen(_take);
    ref.onDispose(subscription.cancel);
    return const {};
  }

  void _take(DetectedPlayback event) {
    _log.fine('${event.source} ${event.state.name}: ${event.title}');
    final next = {...state};
    if (event.state == DetectedState.gone) {
      if (next.remove(event.source) == null) return;
    } else {
      next[event.source] = event;
    }
    state = next;
  }
}

final currentDetectionProvider = Provider<DetectedPlayback?>((ref) {
  final all = ref.watch(detectedPlaybacksProvider).values;
  DetectedPlayback? best;
  for (final event in all) {
    if (event.title == null || event.state == DetectedState.stopped) continue;
    if (best == null || _before(event, best)) best = event;
  }
  return best;
});

bool _before(DetectedPlayback a, DetectedPlayback b) {
  final byState = _stateRank(a) - _stateRank(b);
  if (byState != 0) return byState > 0;
  return _updatedMs(a) > _updatedMs(b);
}

int _stateRank(DetectedPlayback event) => switch (event.state) {
  DetectedState.playing => 2,
  DetectedState.buffering => 1,
  _ => 0,
};

int _updatedMs(DetectedPlayback event) =>
    event.positionUpdatedAt?.millisecondsSinceEpoch ?? 0;
