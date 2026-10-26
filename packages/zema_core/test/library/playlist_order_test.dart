import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  group('playlistNameKey', () {
    test('ignores letter case and surrounding spaces', () {
      expect(playlistNameKey('  Kidase '), 'kidase');
      expect(playlistNameKey('KIDASE'), playlistNameKey('kidase'));
      expect(playlistNameKey('ቅዳሴ'), 'ቅዳሴ');
    });

    test('a name of only spaces is empty', () {
      expect(playlistNameKey('   '), isEmpty);
    });
  });

  group('applyVisibleOrder', () {
    test('without hidden songs the visible order is the stored order', () {
      expect(applyVisibleOrder([1, 2, 3], [3, 1, 2]), [3, 1, 2]);
    });

    test('hidden songs keep their slots', () {
      // 9 is hidden; 1 moves from first to last among the visible songs.
      expect(applyVisibleOrder([1, 9, 2, 3], [2, 3, 1]), [2, 9, 3, 1]);
      expect(applyVisibleOrder([9, 1, 2, 8], [2, 1]), [9, 2, 1, 8]);
    });

    test('ignores IDs that are not stored', () {
      expect(applyVisibleOrder([1, 2], [2, 7, 1]), [2, 1]);
    });

    test('a stored song left out of the visible order stays put', () {
      // E.g. swiped away while the removal is still being saved.
      expect(applyVisibleOrder([1, 2, 3], [3, 1]), [3, 2, 1]);
    });
  });
}
