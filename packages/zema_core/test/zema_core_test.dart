import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart' as zema_core;

void main() {
  group('zema_core', () {
    test('library can be imported when it has no exports yet', () {
      // Placeholder so `dart test` has a test to run until real logic lands.
      expect(zema_core.packageName, 'zema_core');
    });
  });
}
