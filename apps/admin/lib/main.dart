import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/browser.dart';
import 'src/session.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        browserProvider.overrideWithValue(const PageBrowser()),
        sessionStoreProvider.overrideWithValue(const LocalSessionStore()),
        redirectStorageProvider.overrideWithValue(const LocalRedirectStorage()),
      ],
      child: const AdminApp(),
    ),
  );
}
