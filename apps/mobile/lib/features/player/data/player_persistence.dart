import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

/// The queue as it was when the app last saved it.
class SavedQueue {
  const SavedQueue({
    required this.trackIds,
    required this.index,
    required this.position,
    required this.repeat,
  });

  /// Zema track IDs in play order.
  final List<int> trackIds;
  final int index;
  final Duration position;
  final QueueRepeat repeat;
}

/// Saves and loads the queue in `shared_preferences`, keyed by Zema track
/// IDs so it survives rescans and moved files.
class PlayerPersistence {
  PlayerPersistence(this._prefs);

  static const queueKey = 'playerQueue';
  static const indexKey = 'playerIndex';
  static const positionKey = 'playerPositionMs';
  static const repeatKey = 'playerRepeat';

  final SharedPreferences _prefs;

  Future<void> save({
    required List<Track> queue,
    required int index,
    required Duration position,
    required QueueRepeat repeat,
  }) async {
    await _prefs.setStringList(queueKey, [for (final t in queue) '${t.id}']);
    await _prefs.setInt(indexKey, index);
    await _prefs.setInt(positionKey, position.inMilliseconds);
    await _prefs.setString(repeatKey, repeat.name);
  }

  /// The saved queue, or null when nothing (valid) was saved.
  SavedQueue? load() {
    final ids = _prefs
        .getStringList(queueKey)
        ?.map(int.tryParse)
        .whereType<int>()
        .toList();
    if (ids == null || ids.isEmpty) return null;
    final index = _prefs.getInt(indexKey) ?? 0;
    return SavedQueue(
      trackIds: ids,
      index: index.clamp(0, ids.length - 1),
      position: Duration(milliseconds: _prefs.getInt(positionKey) ?? 0),
      repeat: QueueRepeat.values.firstWhere(
        (r) => r.name == _prefs.getString(repeatKey),
        orElse: () => QueueRepeat.off,
      ),
    );
  }
}
