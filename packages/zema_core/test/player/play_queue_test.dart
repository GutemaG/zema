import 'dart:math';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

PlayQueue<String> _queue(
  List<String> items, {
  int start = 0,
  bool shuffle = false,
  QueueRepeat repeat = QueueRepeat.off,
}) => PlayQueue<String>(random: Random(1))
  ..load(items, start: start, shuffle: shuffle)
  ..repeat = repeat;

const _abcd = ['a', 'b', 'c', 'd'];

void main() {
  group('PlayQueue', () {
    test('starts empty', () {
      final queue = PlayQueue<String>();

      expect(queue.isEmpty, isTrue);
      expect(queue.current, isNull);
      expect(queue.index, -1);
      expect(queue.next(), isFalse);
      expect(queue.previous(Duration.zero), isFalse);
      expect(queue.trackCompleted(), QueueAdvance.finished);
    });

    test('loads a list at a start index', () {
      final queue = _queue(_abcd, start: 2);

      expect(queue.items, _abcd);
      expect(queue.current, 'c');
      expect(queue.index, 2);
    });

    test('clamps the start index', () {
      expect(_queue(_abcd, start: 9).current, 'd');
      expect(_queue(const [], start: 3).current, isNull);
    });

    group('next', () {
      test('moves forward and stops at the end with repeat off', () {
        final queue = _queue(_abcd, start: 2);

        expect(queue.next(), isTrue);
        expect(queue.current, 'd');
        expect(queue.next(), isFalse);
        expect(queue.current, 'd');
      });

      test('wraps to the first track with repeat all', () {
        final queue = _queue(_abcd, start: 3, repeat: QueueRepeat.all);

        expect(queue.next(), isTrue);
        expect(queue.current, 'a');
      });

      test('still moves on with repeat one', () {
        final queue = _queue(_abcd, repeat: QueueRepeat.one);

        expect(queue.next(), isTrue);
        expect(queue.current, 'b');
      });
    });

    group('previous', () {
      test('restarts the track when more than 3 s in', () {
        final queue = _queue(_abcd, start: 2);

        expect(queue.previous(const Duration(seconds: 4)), isFalse);
        expect(queue.current, 'c');
      });

      test('goes back within the first 3 s', () {
        final queue = _queue(_abcd, start: 2);

        expect(queue.previous(const Duration(seconds: 3)), isTrue);
        expect(queue.current, 'b');
      });

      test('restarts the first track with repeat off', () {
        final queue = _queue(_abcd);

        expect(queue.previous(Duration.zero), isFalse);
        expect(queue.current, 'a');
      });

      test('wraps to the last track with repeat all', () {
        final queue = _queue(_abcd, repeat: QueueRepeat.all);

        expect(queue.previous(Duration.zero), isTrue);
        expect(queue.current, 'd');
      });
    });

    group('trackCompleted', () {
      test('advances, then finishes at the end with repeat off', () {
        final queue = _queue(['a', 'b']);

        expect(queue.trackCompleted(), QueueAdvance.advanced);
        expect(queue.current, 'b');
        expect(queue.trackCompleted(), QueueAdvance.finished);
        expect(queue.current, 'b');
      });

      test('starts over with repeat all', () {
        final queue = _queue(['a', 'b'], start: 1, repeat: QueueRepeat.all);

        expect(queue.trackCompleted(), QueueAdvance.advanced);
        expect(queue.current, 'a');
      });

      test('replays the track with repeat one', () {
        final queue = _queue(_abcd, start: 1, repeat: QueueRepeat.one);

        expect(queue.trackCompleted(), QueueAdvance.replay);
        expect(queue.current, 'b');
      });

      test('a queue of one with repeat all plays it again', () {
        final queue = _queue(['a'], repeat: QueueRepeat.all);

        expect(queue.trackCompleted(), QueueAdvance.advanced);
        expect(queue.current, 'a');
      });
    });

    group('shuffle', () {
      test('keeps the current track first and shuffles the rest', () {
        final items = [for (var i = 0; i < 20; i++) '$i'];
        final queue = _queue(items, start: 5)..setShuffle(true);

        expect(queue.shuffle, isTrue);
        expect(queue.current, '5');
        expect(queue.index, 0);
        expect(queue.items.toSet(), items.toSet());
        expect(queue.items.skip(1), isNot(orderedEquals(items..remove('5'))));
      });

      test('turning it off restores the order at the current track', () {
        final queue = _queue(_abcd, start: 1)..setShuffle(true);
        queue.next();
        final playing = queue.current;

        queue.setShuffle(false);

        expect(queue.items, _abcd);
        expect(queue.current, playing);
        expect(queue.index, _abcd.indexOf(playing!));
      });

      test('load with shuffle plays the chosen track first', () {
        final queue = _queue(_abcd, start: 2, shuffle: true);

        expect(queue.current, 'c');
        expect(queue.index, 0);
      });

      test('setting the same value twice does nothing', () {
        final queue = _queue(_abcd, start: 2);

        queue.setShuffle(false);

        expect(queue.items, _abcd);
        expect(queue.index, 2);
      });
    });

    group('editing', () {
      test('insertNext puts items right after the current one', () {
        final queue = _queue(_abcd, start: 1)..insertNext(['x', 'y']);

        expect(queue.items, ['a', 'b', 'x', 'y', 'c', 'd']);
        expect(queue.current, 'b');
      });

      test('add puts items at the end', () {
        final queue = _queue(['a'])..add(['x']);

        expect(queue.items, ['a', 'x']);
      });

      test('adding to an empty queue starts it', () {
        final queue = PlayQueue<String>()..add(['x', 'y']);

        expect(queue.current, 'x');
      });

      test('the same item can be queued twice and removed separately', () {
        final queue = _queue(['a', 'b'])..add(['a']);

        expect(queue.removeAt(2), isNotNull);
        expect(queue.items, ['a', 'b']);
        expect(queue.current, 'a');
      });

      test('removing before the current item keeps it playing', () {
        final queue = _queue(_abcd, start: 2);

        expect(queue.removeAt(0), isNotNull);
        expect(queue.items, ['b', 'c', 'd']);
        expect(queue.current, 'c');
      });

      test('the current item cannot be removed', () {
        final queue = _queue(_abcd, start: 2);

        expect(queue.removeAt(2), isNull);
        expect(queue.items, _abcd);
      });

      test('move reorders and follows the current item', () {
        final queue = _queue(_abcd, start: 1)..move(3, 0);

        expect(queue.items, ['d', 'a', 'b', 'c']);
        expect(queue.current, 'b');
        expect(queue.index, 2);
      });

      test('items inserted while shuffled survive turning shuffle off', () {
        final queue = _queue(_abcd, start: 1, shuffle: true)..insertNext(['x']);
        expect(queue.items[1], 'x');

        queue.setShuffle(false);

        expect(queue.items, ['a', 'b', 'x', 'c', 'd']);
      });

      test('clearUpcoming keeps only what played so far and now', () {
        final queue = _queue(_abcd, start: 1)..clearUpcoming();

        expect(queue.items, ['a', 'b']);
        expect(queue.current, 'b');
        expect(queue.hasNext, isFalse);
      });

      test('jumpTo plays any item', () {
        final queue = _queue(_abcd)..jumpTo(3);

        expect(queue.current, 'd');
        expect(() => queue.jumpTo(4), throwsRangeError);
      });
    });

    group('entry keys and undo', () {
      test('each entry has its own key, even the same item twice', () {
        final queue = _queue(['a', 'b'])..add(['a']);

        expect(queue.keys, hasLength(3));
        expect(queue.keys.toSet(), hasLength(3));
      });

      test('a moved entry keeps its key', () {
        final queue = _queue(_abcd);
        final keyOfD = queue.keys[3];

        queue.move(3, 0);

        expect(queue.keys.first, keyOfD);
      });

      test('restore puts a removed item back where it was', () {
        final queue = _queue(_abcd, start: 1);
        final keys = queue.keys;

        final removal = queue.removeAt(2)!;
        expect(removal.item, 'c');
        expect(queue.restore(removal), isTrue);

        expect(queue.items, _abcd);
        expect(queue.keys, keys);
        expect(queue.current, 'b');
      });

      test('restoring an item before the current one keeps it playing', () {
        final queue = _queue(_abcd, start: 2);

        final removal = queue.removeAt(0)!;
        expect(queue.index, 1);
        queue.restore(removal);

        expect(queue.items, _abcd);
        expect(queue.current, 'c');
        expect(queue.index, 2);
      });

      test('restore while shuffled also restores the original order', () {
        final queue = _queue(_abcd, shuffle: true);
        final shuffled = queue.items;

        final removal = queue.removeAt(2)!;
        queue.restore(removal);
        expect(queue.items, shuffled);

        queue.setShuffle(false);
        expect(queue.items, _abcd);
      });

      test('restore fits the item in when the queue got shorter', () {
        final queue = _queue(_abcd);

        final removal = queue.removeAt(3)!;
        queue.clearUpcoming();
        queue.restore(removal);

        expect(queue.items, ['a', 'd']);
      });

      test('restore does nothing twice or after a new queue loads', () {
        final queue = _queue(_abcd);
        final removal = queue.removeAt(1)!;

        expect(queue.restore(removal), isTrue);
        expect(queue.restore(removal), isFalse);
        expect(queue.items, _abcd);

        final again = queue.removeAt(1)!;
        queue.load(['x', 'y']);
        expect(queue.restore(again), isFalse);
        expect(queue.items, ['x', 'y']);
      });
    });
  });
}
