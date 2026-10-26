/// The key that keeps playlist names unique: trimmed and lowercased, so
/// "Kidase" and " kidase " count as the same name.
String playlistNameKey(String name) => name.trim().toLowerCase();

/// A playlist's stored order ([stored], every track ID) after the user
/// reordered the songs they can see into [visible].
///
/// Only the songs in [visible] move, filling the slots those songs held.
/// Hidden or missing songs keep their slots, so they come back in place if
/// they become visible again. IDs in [visible] that aren't stored are
/// ignored.
List<int> applyVisibleOrder(List<int> stored, List<int> visible) {
  final storedSet = stored.toSet();
  final order = [
    for (final id in visible)
      if (storedSet.contains(id)) id,
  ];
  final shown = order.toSet();
  var next = 0;
  return [for (final id in stored) shown.contains(id) ? order[next++] : id];
}
