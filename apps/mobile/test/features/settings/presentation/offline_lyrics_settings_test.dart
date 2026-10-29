import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/settings/presentation/widgets/settings_row.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/bundled_lyrics_repository.dart';
import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _App {
  _App(this.db, this.catalog);

  final ZemaDatabase db;
  final FakeCatalogRepository catalog;

  Future<int> cachedCount() async =>
      (await db.cachedSongsDao.watchSongs().first).length;
}

/// Lets database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Home with the sample catalog's index saved. With [extra], the index
/// also lists that many songs the server no longer has (they count as done
/// with nothing saved), so the download takes two batches.
Future<_App> _pump(
  WidgetTester tester, {
  int extra = 0,
  bool backendConfigured = true,
}) async {
  useScreen(tester, size: const Size(360, 2400));
  final lyrics = BundledLyricsRepository(DiskAssetBundle());
  final catalog = FakeCatalogRepository(lyrics: lyrics);
  if (extra > 0) {
    catalog.entries = [
      for (final song in await tester.runAsync(lyrics.songs) ?? <Song>[])
        catalogEntry(song),
      for (var i = 0; i < extra; i++)
        catalogEntry(Song(id: 'zz-$i', title: 'Gone $i', sections: const [])),
    ];
  }
  final db = memoryDatabase();
  await pumpZemaApp(
    tester,
    database: db,
    catalog: catalog,
    backendConfigured: backendConfigured,
  );
  await _settle(tester);
  return _App(db, catalog);
}

/// Starts Download all. While it runs the progress bar may animate (with
/// no value while the index is checked), so frames are pumped, not
/// settled.
Future<void> _start(WidgetTester tester) async {
  await tester.tap(_row(_l10n.settingsLyricsDownloadAll));
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await _settle(tester);
}

Finder _row(String label) => find.widgetWithText(SettingsRow, label);

String? _value(WidgetTester tester, String label) =>
    tester.widget<SettingsRow>(_row(label)).value;

bool _enabled(WidgetTester tester, String label) =>
    tester.widget<SettingsRow>(_row(label)).onTap != null;

Finder get _cancel => find.descendant(
  of: _row(_l10n.settingsLyricsDownloadAll),
  matching: find.widgetWithText(TextButton, _l10n.actionCancel),
);

void main() {
  testWidgets('nothing downloaded: "None yet", and Clear is off', (
    tester,
  ) async {
    await _pump(tester);
    await _openSettings(tester);

    expect(
      _value(tester, _l10n.settingsLyricsDownloaded),
      _l10n.settingsLyricsDownloadedNone,
    );
    expect(_enabled(tester, _l10n.settingsLyricsDownloadAll), isTrue);
    expect(_enabled(tester, _l10n.settingsLyricsClear), isFalse);
  });

  testWidgets('Download all shows progress with Cancel, then the storage '
      'used', (tester) async {
    final app = await _pump(tester);
    await _openSettings(tester);
    final gate = app.catalog.songGate = Completer<void>();

    await _start(tester);
    expect(find.text(_l10n.settingsLyricsDownloadProgress(0, 3)), findsOne);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_cancel, findsOneWidget);
    expect(_enabled(tester, _l10n.settingsLyricsDownloadAll), isFalse);
    expect(_enabled(tester, _l10n.settingsLyricsClear), isFalse);

    gate.complete();
    await _settle(tester);
    expect(find.text(_l10n.settingsLyricsDownloadDone), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(_cancel, findsNothing);
    expect(await tester.runAsync(app.cachedCount), 3);
    expect(
      _value(tester, _l10n.settingsLyricsDownloaded),
      matches(RegExp(r'^3 songs · \d+ (B|KB)$')),
    );
    expect(_enabled(tester, _l10n.settingsLyricsClear), isTrue);
  });

  testWidgets('Cancel stops after the first batch', (tester) async {
    final app = await _pump(tester, extra: 3);
    await _openSettings(tester);
    final gate = app.catalog.songGate = Completer<void>();

    await _start(tester);
    expect(find.text(_l10n.settingsLyricsDownloadProgress(0, 6)), findsOne);
    await tester.tap(_cancel);
    gate.complete();
    await _settle(tester);

    expect(
      find.text(_l10n.settingsLyricsDownloadCancelled(4, 6)),
      findsOneWidget,
    );
    expect(app.catalog.songCalls, hasLength(4));
    expect(_enabled(tester, _l10n.settingsLyricsDownloadAll), isTrue);
  });

  testWidgets('offline, the download stops with a message', (tester) async {
    final app = await _pump(tester);
    await _openSettings(tester);
    app.catalog.failure = const NetworkFailure('offline');

    await _start(tester);

    expect(
      find.text(_l10n.settingsLyricsDownloadOffline(0, 3)),
      findsOneWidget,
    );
    expect(_enabled(tester, _l10n.settingsLyricsDownloadAll), isTrue);
  });

  testWidgets('another failure says something went wrong', (tester) async {
    final app = await _pump(tester);
    await _openSettings(tester);
    app.catalog.failure = const BackendFailure('500');

    await _start(tester);

    expect(find.text(_l10n.settingsLyricsDownloadFailed(0, 3)), findsOne);
  });

  testWidgets('leaving Settings mid-download: it goes on, and progress '
      'shows on return', (tester) async {
    final app = await _pump(tester);
    await _openSettings(tester);
    final gate = app.catalog.songGate = Completer<void>();
    await _start(tester);

    await tester.pageBack();
    await _settle(tester);
    expect(find.byType(SettingsRow), findsNothing);
    await _openSettings(tester);
    expect(find.text(_l10n.settingsLyricsDownloadProgress(0, 3)), findsOne);
    expect(_cancel, findsOneWidget);

    await tester.pageBack();
    await _settle(tester);
    gate.complete();
    await _settle(tester);
    expect(await tester.runAsync(app.cachedCount), 3);
    await _openSettings(tester);
    expect(find.text(_l10n.settingsLyricsDownloadDone), findsOneWidget);
  });

  testWidgets('Clear asks first; Cancel keeps the lyrics, Clear removes '
      'them', (tester) async {
    final app = await _pump(tester);
    await _openSettings(tester);
    await _start(tester);
    await _settle(tester);

    await tester.tap(_row(_l10n.settingsLyricsClear));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.settingsLyricsClearTitle), findsOneWidget);
    expect(find.text(_l10n.settingsLyricsClearMessage), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, _l10n.actionCancel));
    await _settle(tester);
    expect(await tester.runAsync(app.cachedCount), 3);

    await tester.tap(_row(_l10n.settingsLyricsClear));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, _l10n.settingsLyricsClearConfirm),
    );
    await _settle(tester);
    expect(await tester.runAsync(app.cachedCount), 0);
    expect(
      await tester.runAsync(() => app.db.catalogDao.watchEntries().first),
      hasLength(3),
    );
    expect(
      _value(tester, _l10n.settingsLyricsDownloaded),
      _l10n.settingsLyricsDownloadedNone,
    );
    expect(find.text(_l10n.settingsLyricsDownloadDone), findsNothing);
    expect(_enabled(tester, _l10n.settingsLyricsClear), isFalse);
  });

  testWidgets('a build with no backend: Download all is off', (tester) async {
    await _pump(tester, backendConfigured: false);
    await _openSettings(tester);

    expect(find.text(_l10n.settingsLyricsDownloadUnavailable), findsOneWidget);
    expect(_enabled(tester, _l10n.settingsLyricsDownloadAll), isFalse);
  });
}
