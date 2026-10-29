import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeGoogleAccountPicker picker;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    picker = FakeGoogleAccountPicker();
    container = ProviderContainer(
      overrides: accountOverrides(auth: auth, picker: picker),
    );
    addTearDown(container.dispose);
    // Kept listened, as S24 does.
    container.listen(signInProvider, (_, _) {});
  });

  SignInController controller() => container.read(signInProvider.notifier);

  test('a second sign-in while one is running is ignored', () async {
    picker.gate = Completer<void>();
    final first = controller().signIn();
    expect(container.read(signInProvider).isLoading, isTrue);

    expect(await controller().signIn(), isNull);
    expect(picker.picks, 1);

    picker.gate!.complete();
    expect(await first, testUser);
    expect(auth.idTokens, hasLength(1));
    expect(container.read(signInProvider), const AsyncData<void>(null));
  });

  test('a cancel ends idle, with no error', () async {
    picker.tokens = null;
    expect(await controller().signIn(), isNull);
    expect(container.read(signInProvider), const AsyncData<void>(null));
  });

  test('a failure is held as the ZemaFailure', () async {
    auth.signInFailure = const NetworkFailure('offline');
    expect(await controller().signIn(), isNull);
    expect(container.read(signInProvider).error, isA<NetworkFailure>());
  });

  test('without a picker (no Google IDs) it does nothing', () async {
    final noPicker = ProviderContainer(overrides: accountOverrides(auth: auth));
    addTearDown(noPicker.dispose);
    noPicker.listen(signInProvider, (_, _) {});
    expect(await noPicker.read(signInProvider.notifier).signIn(), isNull);
    expect(auth.idTokens, isEmpty);
  });
}
