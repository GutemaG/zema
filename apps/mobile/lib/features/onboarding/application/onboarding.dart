import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';

final onboardingPendingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<bool> {
  static const key = 'onboardingDone';

  @override
  bool build() => !(ref.read(sharedPreferencesProvider).getBool(key) ?? false);

  Future<void> done() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(key, true);
  }
}
