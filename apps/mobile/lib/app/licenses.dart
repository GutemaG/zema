import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled fonts and their SIL Open Font License texts in `assets/fonts/`.
const Map<String, String> fontLicenseAssets = {
  'Inter': 'assets/fonts/OFL-Inter.txt',
  'Noto Sans Ethiopic': 'assets/fonts/OFL-NotoSansEthiopic.txt',
};

/// Adds the bundled font licenses to the app's license page. Call once from
/// `main()` before `runApp`.
void registerFontLicenses({AssetBundle? bundle}) {
  final assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: path) in fontLicenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([font], await assets.loadString(path));
    }
  });
}
