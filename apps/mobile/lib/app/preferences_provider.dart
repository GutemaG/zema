import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The loaded `SharedPreferences`, for small flags that are not user
/// settings. Set in `main()` by `loadSettingsOverrides()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with loaded '
    'SharedPreferences (see loadSettingsOverrides).',
  ),
);
