import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed build as `version (build)`, e.g. `1.0.0 (1)`.
///
/// Not retried: if the platform can't report the version, asking again won't
/// help, and retrying would keep the row in its loading state instead of
/// showing the error.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}, retry: (_, _) => null);
