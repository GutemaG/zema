import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LicenseRegistry.reset);

  group('registerFontLicenses', () {
    test('adds the OFL license for each bundled font', () async {
      registerFontLicenses();

      final entries = await LicenseRegistry.licenses.toList();
      final byPackage = {
        for (final entry in entries)
          for (final package in entry.packages)
            package: entry.paragraphs.map((p) => p.text).join('\n'),
      };

      for (final font in ['Inter', 'Noto Sans Ethiopic']) {
        expect(byPackage, contains(font));
        expect(byPackage[font], contains('SIL Open Font License'));
      }
    });
  });
}
