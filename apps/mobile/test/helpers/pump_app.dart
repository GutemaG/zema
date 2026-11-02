import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart'
    show
        AuthRepository,
        BackupRepository,
        CatalogRepository,
        LyricsRepository,
        ProfileRepository;
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/l10n/language_providers.dart';
import 'package:zema/app/router.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/theme/zema_theme.dart';
import 'package:zema/app/zema_app.dart';
import 'package:zema/features/account/data/avatar_cache.dart';
import 'package:zema/features/account/data/google_account_picker.dart';
import 'package:zema/features/contribute/application/recording.dart';
import 'package:zema/features/contribute/data/shared_audio.dart';
import 'package:zema/features/contribute/data/sync_player.dart';
import 'package:zema/features/contribute/data/youtube_info.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/data/audio_share_service.dart';
import 'package:zema/features/library/data/library_scanner.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/settings/application/app_version_provider.dart';
import 'package:zema/features/settings/application/settings_bootstrap.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

import 'fake_auth.dart';
import 'fake_contribute.dart';
import 'fake_library.dart';
import 'fake_lyrics.dart';
import 'fake_player.dart';

/// Pumps the full app the way `main()` starts it: settings are loaded from
/// (mocked) saved preferences before the first frame.
///
/// [savedPrefs] are the stored values, e.g. `{'paletteId': 'wine'}`;
/// [savedLanguage] is shorthand for `{'localeCode': …}`. The device locale
/// list, the phone's light/dark setting ([phoneBrightness], dark by default
/// so the System theme renders the dark palettes), start route and app
/// version are faked. The device library is faked too: [libraryScanner]
/// (empty by default), [permissions] (granted by default), [database]
/// (in-memory by default; pass one to seed or inspect it) and
/// [shareService], and so is the player ([audioHandler], over a fake backend by
/// default). Lyrics come from [catalog], by default a fake one serving
/// [lyricsRepository] (the sample fixtures unless given). Accounts use [auth]
/// and [profiles], by default a fake where the user is a guest; sign-in (and
/// so the account choice) is offered only with a [googlePicker]; avatars
/// come from [avatars] and the cloud backup from [backups]; the phone is on Wi-Fi only when
/// [onWifi] says so. With [settle]
/// false only the first frame is pumped.
Future<void> pumpZemaApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  List<Locale> deviceLocales = const [Locale('en')],
  Brightness phoneBrightness = Brightness.dark,
  String? savedLanguage,
  Map<String, Object> savedPrefs = const {},
  Future<String> Function()? appVersion,
  LibraryScanner? libraryScanner,
  AudioPermissionService? permissions,
  ZemaDatabase? database,
  AudioShareService? shareService,
  ZemaAudioHandler? audioHandler,
  LyricsRepository? lyricsRepository,
  CatalogRepository? catalog,
  bool backendConfigured = true,
  AuthRepository? auth,
  ProfileRepository? profiles,
  GoogleAccountPicker? googlePicker,
  AvatarCache? avatars,
  BackupRepository? backups,
  bool Function()? onWifi,
  YoutubeInfoService? youtube,
  ShareReceiver? shareReceiver,
  SyncPlayer? syncPlayer,
  bool settle = true,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = phoneBrightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  SharedPreferences.setMockInitialValues({
    ...savedPrefs,
    'localeCode': ?savedLanguage,
  });
  final settingsOverrides = await loadSettingsOverrides();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...settingsOverrides,
        ...libraryOverrides(
          scanner: libraryScanner,
          permissions: permissions,
          database: database,
          shareService: shareService,
        ),
        ...playerOverrides(handler: audioHandler),
        ...lyricsOverrides(
          repository: lyricsRepository,
          catalog: catalog,
          backendConfigured: backendConfigured,
        ),
        ...accountOverrides(
          auth: auth,
          profiles: profiles,
          picker: googlePicker,
          avatars: avatars,
          backups: backups,
          onWifi: onWifi,
          backendConfigured: backendConfigured,
        ),
        youtubeInfoServiceProvider.overrideWithValue(
          youtube ?? FakeYoutubeInfoService(),
        ),
        shareReceiverProvider.overrideWithValue(
          shareReceiver ?? FakeShareReceiver(),
        ),
        syncPlayerProvider.overrideWithValue(
          () => syncPlayer ?? FakeSyncPlayer(),
        ),
        deviceLocalesProvider.overrideWithValue(deviceLocales),
        appVersionProvider.overrideWith(
          (ref) => appVersion?.call() ?? Future.value('1.0.0 (1)'),
        ),
        routerProvider.overrideWith((ref) {
          final router = buildRouter(ref, initialLocation: location);
          ref.onDispose(router.dispose);
          return router;
        }),
      ],
      child: const ZemaApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

/// The saved preferences as the app left them.
Future<SharedPreferences> savedPreferences() => SharedPreferences.getInstance();

/// Pumps [child] inside the app theme and English localizations, without the
/// router. For testing shared widgets on their own.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(ZemaPalette.fallback, Brightness.dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sets a phone-sized screen and text scale for this test; both are reset
/// when the test ends.
void useScreen(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1,
}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
