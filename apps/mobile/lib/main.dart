import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/licenses.dart';
import 'app/zema_app.dart';

void main() {
  registerFontLicenses();
  runApp(const ProviderScope(child: ZemaApp()));
}
