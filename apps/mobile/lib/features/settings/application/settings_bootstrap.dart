import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/preferences_provider.dart';
import '../data/settings_repository.dart';
import 'settings_controller.dart';

/// Loads saved settings and returns the `ProviderScope` overrides that make
/// them available from the first frame. Call before `runApp`.
Future<List<Override>> loadSettingsOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  final repository = SettingsRepository(prefs);
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    settingsRepositoryProvider.overrideWithValue(repository),
    initialSettingsProvider.overrideWithValue(repository.load()),
  ];
}
