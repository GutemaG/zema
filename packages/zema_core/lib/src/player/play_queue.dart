import 'dart:math';

/// What happens when the queue reaches the end of a track.
enum QueueRepeat { off, all, one }

/// The result of [PlayQueue.trackCompleted].
enum QueueAdvance {
  /// Play the same track again (repeat one).
  replay,

  /// Moved to another track.
  advanced,

  /// The queue ended; playback should stop.
  finished,
}

/// The play order of a queue: what plays now, what plays next, shuffle and
/// repeat. Pure logic: it never plays anything itself.
///
/// The same item may appear more than once (e.g. added to the queue twice);
/// each appearance is tracked separately.
class PlayQueue<T> {
  PlayQueue({Random? random}) : _random = random ?? Random();

  /// Within this much of the start, "previous" goes to the previous track;
  /// later it restarts the current one.
  static const restartThreshold = Duration(seconds: 3);

  final Random _random;
  var _nextKey = 0;

  /// Bumped by [load], so a removal from an earlier queue isn't restored
  /// into a new one.
  var _generation = 0;

  /// Order as loaded and edited, ignoring shuffle.
  var _original = <_Entry<T>>[];

  /// The order things actually play in.
  var _order = <_Entry<T>>[];
  var _index = -1;
  var _shuffle = false;

  /// What happens at the end of a track.
  QueueRepeat repeat = QueueRepeat.off;

  /// Items in play order.
  List<T> get items => List.unmodifiable(_order.map((e) => e.item));

  /// A stable key for each entry in [items], in the same order. An item
  /// queued twice has two keys; a moved entry keeps its key.
  List<int> get keys => List.unmodifiable(_order.map((e) => e.key));

  /// Position of [current] in [items], or -1 when empty.
  int get index => _index;
  T? get current => _index < 0 ? null : _order[_index].item;
  bool get isEmpty => _order.isEmpty;
  int get length => _order.length;
  bool get shuffle => _shuffle;

  bool get hasNext => _index >= 0 && _index < _order.length - 1;

  /// Replaces the queue with [items], starting at [start] (an index into
  /// [items]). With [shuffle], that item plays first and the rest follow in
  /// random order.
  void load(List<T> items, {int start = 0, bool shuffle = false}) {
    _generation++;
    _original = [for (final item in items) _Entry(item, _nextKey++)];
    _order = [..._original];
    _index = _order.isEmpty ? -1 : start.clamp(0, _order.length - 1);
    _shuffle = false;
    if (shuffle) setShuffle(true);
  }

  /// Shuffle on keeps the current item and shuffles everything else after
  /// it. Shuffle off returns to the original order, still at the current
  /// item.
  void setShuffle(bool on) {
    if (on == _shuffle) return;
    _shuffle = on;
    if (_order.isEmpty) return;
    final now = _order[_index];
    if (on) {
      final rest = [..._original]..remove(now);
      rest.shuffle(_random);
      _order = [now, ...rest];
      _index = 0;
    } else {
      _order = [..._original];
      _index = _order.indexOf(now);
    }
  }

  /// The user pressed next. Returns false when there is nothing after the
  /// current item and repeat is off (nothing changes).
  bool next() {
    if (_order.isEmpty) return false;
    if (hasNext) {
      _index++;
      return true;
    }
    if (repeat == QueueRepeat.all) {
      _index = 0;
      return true;
    }
    return false;
  }

  /// The user pressed previous at [position] in the current track. Returns
  /// true when the queue moved back; false means "restart the current
  /// track".
  bool previous(Duration position) {
    if (_order.isEmpty || position > restartThreshold) return false;
    if (_index > 0) {
      _index--;
      return true;
    }
    if (repeat == QueueRepeat.all && _order.length > 1) {
      _index = _order.length - 1;
      return true;
    }
    return false;
  }

  /// The current track played to its end.
  QueueAdvance trackCompleted() {
    if (_order.isEmpty) return QueueAdvance.finished;
    if (repeat == QueueRepeat.one) return QueueAdvance.replay;
    if (hasNext) {
      _index++;
      return QueueAdvance.advanced;
    }
    if (repeat == QueueRepeat.all) {
      _index = 0;
      return QueueAdvance.advanced;
    }
    return QueueAdvance.finished;
  }

  /// Plays the item at [index] in [items] next.
  void jumpTo(int index) {
    RangeError.checkValidIndex(index, _order);
    _index = index;
  }

  /// Puts [items] right after the current item.
  void insertNext(List<T> items) {
    if (_order.isEmpty) return load(items);
    final entries = [for (final item in items) _Entry(item, _nextKey++)];
    final now = _order[_index];
    _order.insertAll(_index + 1, entries);
    _original.insertAll(_original.indexOf(now) + 1, entries);
  }

  /// Puts [items] at the end of the queue.
  void add(List<T> items) {
    if (_order.isEmpty) return load(items);
    final entries = [for (final item in items) _Entry(item, _nextKey++)];
    _order.addAll(entries);
    _original.addAll(entries);
  }

  /// Removes the item at [index] in [items] and returns what [restore]
  /// needs to put it back. The current item cannot be removed; returns null
  /// if asked to.
  QueueRemoval<T>? removeAt(int index) {
    RangeError.checkValidIndex(index, _order);
    if (index == _index) return null;
    final entry = _order.removeAt(index);
    final originalIndex = _original.indexOf(entry);
    _original.removeAt(originalIndex);
    if (index < _index) _index--;
    return QueueRemoval._(entry, index, originalIndex, _generation);
  }

  /// Puts back an item taken out by [removeAt], at the same place in both
  /// the play order and the original order (or as close as the queue now
  /// allows). Returns false when the queue was replaced since, or the item
  /// is already back.
  bool restore(QueueRemoval<T> removal) {
    final entry = removal._entry;
    if (removal._generation != _generation || _order.contains(entry)) {
      return false;
    }
    final at = removal._orderIndex.clamp(0, _order.length);
    _order.insert(at, entry);
    if (at <= _index) _index++;
    _original.insert(removal._originalIndex.clamp(0, _original.length), entry);
    return true;
  }

  /// Moves the item at [from] to [to] (indexes in [items], [to] counted
  /// after removal). Without shuffle the original order changes too.
  void move(int from, int to) {
    RangeError.checkValidIndex(from, _order);
    RangeError.checkValidIndex(to, _order);
    final now = _order[_index];
    final entry = _order.removeAt(from);
    _order.insert(to, entry);
    _index = _order.indexOf(now);
    if (!_shuffle) _original = [..._order];
  }

  /// Removes everything after the current item.
  void clearUpcoming() {
    if (_order.isEmpty) return;
    final upcoming = _order.sublist(_index + 1).toSet();
    _order = _order.sublist(0, _index + 1);
    _original.removeWhere(upcoming.contains);
  }
}

/// An item taken out of a [PlayQueue], for [PlayQueue.restore].
class QueueRemoval<T> {
  QueueRemoval._(
    this._entry,
    this._orderIndex,
    this._originalIndex,
    this._generation,
  );

  final _Entry<T> _entry;
  final int _orderIndex;
  final int _originalIndex;
  final int _generation;

  T get item => _entry.item;
}

/// One appearance of an item; identity is the [key], not the item.
class _Entry<T> {
  _Entry(this.item, this.key);

  final T item;
  final int key;

  @override
  bool operator ==(Object other) => other is _Entry<T> && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
