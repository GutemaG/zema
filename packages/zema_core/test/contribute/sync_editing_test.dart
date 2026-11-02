import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

void main() {
  test('taps time the lines in order; after the last one nothing changes', () {
    var starts = List<Duration?>.filled(3, null);
    expect(nextUntimed(starts), 0);
    starts = tapNext(starts, s(1));
    starts = tapNext(starts, s(2.5));
    expect(starts, [s(1), s(2.5), null]);
    expect(nextUntimed(starts), 2);
    starts = tapNext(starts, s(4));
    expect(nextUntimed(starts), isNull);
    expect(tapNext(starts, s(9)), same(starts));
  });

  test('a tap not after the line before is ignored', () {
    final starts = [s(5), null];
    expect(tapNext(starts, s(4)), same(starts));
    expect(tapNext(starts, s(5.05)), same(starts));
    expect(tapNext(starts, s(5.1)), [s(5), s(5.1)]);
  });

  test('undo clears the last line timed', () {
    expect(undoLastTap([s(1), s(2), null]), [s(1), null, null]);
    final none = <Duration?>[null, null];
    expect(undoLastTap(none), same(none));
  });

  test('nudging keeps a gap from the neighbours and stays above zero', () {
    final starts = [s(1), s(2), s(3)];
    expect(nudgeStart(starts, 1, s(0.1)), [s(1), s(2.1), s(3)]);
    expect(nudgeStart(starts, 1, s(-0.1)), [s(1), s(1.9), s(3)]);
    expect(nudgeStart(starts, 1, s(5)), [s(1), s(2.9), s(3)]);
    expect(nudgeStart(starts, 1, s(-5)), [s(1), s(1.1), s(3)]);
    expect(nudgeStart([s(0.05), null], 0, s(-0.1)), [Duration.zero, null]);
    expect(nudgeStart(starts, 2, s(10)), [s(1), s(2), s(13)]);
    final untimed = <Duration?>[null];
    expect(nudgeStart(untimed, 0, s(1)), same(untimed));
  });

  test('redo clears from a line on and plays from 3 s before it', () {
    final starts = [s(1), s(5), s(9)];
    expect(redoFrom(starts, 1), [s(1), null, null]);
    expect(redoPosition(starts, 1), s(2));
    expect(redoPosition(starts, 0), Duration.zero);
    expect(
      redoPosition([s(10), null], 1),
      s(7),
      reason: 'from the line before',
    );
  });

  test('starts fit the lines: kept, or all untimed when the count changed', () {
    final starts = [s(1), null];
    expect(startsFor(starts, 2), same(starts));
    expect(startsFor(starts, 3), [null, null, null]);
  });
}
