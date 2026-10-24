import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/features/player/data/player_persistence.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

Future<PlayerPersistence> _persistence([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  return PlayerPersistence(await SharedPreferences.getInstance());
}

void main() {
  group('PlayerPersistence', () {
    test('has nothing saved at first', () async {
      expect((await _persistence()).load(), isNull);
    });

    test('round-trips the queue by Zema ID', () async {
      final persistence = await _persistence();
      final queue = [
        Track.fromScan(7, scannedAudio(1, '/m/a.mp3')),
        Track.fromScan(3, scannedAudio(2, '/m/b.mp3')),
      ];

      await persistence.save(
        queue: queue,
        index: 1,
        position: const Duration(seconds: 42),
        repeat: QueueRepeat.one,
      );
      final saved = persistence.load()!;

      expect(saved.trackIds, [7, 3]);
      expect(saved.index, 1);
      expect(saved.position, const Duration(seconds: 42));
      expect(saved.repeat, QueueRepeat.one);
    });

    test('ignores broken values', () async {
      final persistence = await _persistence({
        PlayerPersistence.queueKey: ['4', 'x', '9'],
        PlayerPersistence.indexKey: 12,
        PlayerPersistence.repeatKey: 'sideways',
      });

      final saved = persistence.load()!;

      expect(saved.trackIds, [4, 9]);
      expect(saved.index, 1);
      expect(saved.position, Duration.zero);
      expect(saved.repeat, QueueRepeat.off);
    });

    test('treats an empty queue as nothing saved', () async {
      final persistence = await _persistence({
        PlayerPersistence.queueKey: <String>[],
      });

      expect(persistence.load(), isNull);
    });
  });
}
