import 'package:flutter_test/flutter_test.dart';
import 'package:zema/shared/format_bytes.dart';

void main() {
  test('bytes, KB and MB in powers of 1,000', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(999), '999 B');
    expect(formatBytes(1000), '1 KB');
    expect(formatBytes(340400), '340 KB');
    expect(formatBytes(999499), '999 KB');
    expect(formatBytes(999500), '1.0 MB'); // not 1000 KB
    expect(formatBytes(1000000), '1.0 MB');
    expect(formatBytes(1250000), '1.3 MB');
  });
}
