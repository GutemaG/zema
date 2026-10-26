import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The songs selected in Tracks, or null when not selecting. Lives as long
/// as the Tracks tab does.
final trackSelectionProvider =
    NotifierProvider.autoDispose<TrackSelection, Set<int>?>(TrackSelection.new);

class TrackSelection extends Notifier<Set<int>?> {
  @override
  Set<int>? build() => null;

  /// Starts selecting, with [trackId] selected (a long-press).
  void start(int trackId) => state = {trackId};

  /// Selects or deselects [trackId]; deselecting the last one ends
  /// selection.
  void toggle(int trackId) {
    final selected = {...?state};
    if (!selected.remove(trackId)) selected.add(trackId);
    state = selected.isEmpty ? null : selected;
  }

  void selectAll(Iterable<int> trackIds) => state = {...?state, ...trackIds};

  /// Drops songs that are no longer in the library (hidden elsewhere, gone
  /// after a rescan); ends selection if none are left.
  void retain(Set<int> trackIds) {
    final selected = state;
    if (selected == null || trackIds.containsAll(selected)) return;
    final kept = selected.intersection(trackIds);
    state = kept.isEmpty ? null : kept;
  }

  void end() => state = null;
}
