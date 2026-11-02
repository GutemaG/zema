import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  test('reads m:ss and h:mm:ss', () {
    expect(parseDurationText('4:05'), const Duration(minutes: 4, seconds: 5));
    expect(
      parseDurationText(' 12:30 '),
      const Duration(minutes: 12, seconds: 30),
    );
    expect(
      parseDurationText('1:02:03'),
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
  });

  test('refuses anything else, and zero', () {
    for (final text in [
      '',
      '4',
      '4:5',
      '4:60',
      '1:60:00',
      'a:bc',
      '0:00',
      '-1:00',
    ]) {
      expect(parseDurationText(text), isNull, reason: text);
    }
  });

  test('formats and reads back', () {
    for (final d in const [
      Duration(minutes: 4, seconds: 5),
      Duration(hours: 1, minutes: 2, seconds: 3),
      Duration(seconds: 59),
    ]) {
      expect(parseDurationText(formatDurationText(d)), d);
    }
    expect(formatDurationText(const Duration(minutes: 4, seconds: 5)), '4:05');
    expect(formatDurationText(const Duration(hours: 1, seconds: 3)), '1:00:03');
  });
}
