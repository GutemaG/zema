import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('detection.background');

enum PhoneBrand {
  xiaomi,
  samsung,
  huawei,
  oppo,
  vivo,
  oneplus,
  transsion,
  other;

  static PhoneBrand of(String manufacturer) =>
      switch (manufacturer.toLowerCase().trim()) {
        'xiaomi' || 'redmi' || 'poco' => xiaomi,
        'samsung' => samsung,
        'huawei' || 'honor' => huawei,
        'oppo' || 'realme' => oppo,
        'vivo' || 'iqoo' => vivo,
        'oneplus' => oneplus,
        'tecno' || 'infinix' || 'itel' || 'tecno mobile' => transsion,
        _ => other,
      };
}

abstract interface class BackgroundAccess {
  Future<bool> unrestricted();

  Future<void> allow();

  Future<PhoneBrand> brand();

  Future<void> openPhoneSettings();
}

class NoBackgroundAccess implements BackgroundAccess {
  const NoBackgroundAccess();

  @override
  Future<bool> unrestricted() async => true;

  @override
  Future<void> allow() async {}

  @override
  Future<PhoneBrand> brand() async => PhoneBrand.other;

  @override
  Future<void> openPhoneSettings() async {}
}

class AndroidBackgroundAccess implements BackgroundAccess {
  const AndroidBackgroundAccess([
    this._methods = const MethodChannel('zema/detection'),
  ]);

  final MethodChannel _methods;

  @override
  Future<bool> unrestricted() async =>
      await _call<bool>('batteryUnrestricted', 'Checking battery use') ?? true;

  @override
  Future<void> allow() => _call<void>('allowBattery', 'Asking for battery use');

  @override
  Future<PhoneBrand> brand() async => PhoneBrand.of(
    await _call<String>('manufacturer', 'Reading the phone brand') ?? '',
  );

  @override
  Future<void> openPhoneSettings() =>
      _call<void>('openPhoneSettings', 'Opening the phone settings');

  Future<T?> _call<T>(String method, String what) async {
    try {
      return await _methods.invokeMethod<T>(method);
    } on PlatformException catch (e) {
      _log.warning('$what failed', e);
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
