import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/features/catalog/application/catalog_index.dart';
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema/features/home/presentation/widgets/home_rows.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/presentation/song_detail_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/bundled_lyrics_repository.dart';
import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Song [i], approved on day [day] of October.
CatalogEntry _entry(
  String id,
  String title, {
  required int day,
  bool synced = true,
  String? artist,
}) => CatalogEntry(
  id: id,
  title: title,
  artist: artist,
  synced: synced,
  version: 1,
  approvedAt: DateTime.utc(2026, 10, day),
);

/// The sample songs (so they open), approved on different days.
final _samples = [
  _entry('birhan-honlin', 'ብርሃን ሆንልን', day: 3, artist: 'Zema Samples'),
  _entry('galatoomi', 'Galatoomi', day: 20, artist: 'Zema Samples'),
  _entry('selam-lezih-bet', 'ሰላም ለዚህ ቤት', day: 9, synced: false),
];

/// Lets database work finish, then settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Home, with one track on the phone and the catalog listing [entries].
Future<FakeCatalogRepository> _pump(
  WidgetTester tester, {
  List<CatalogEntry>? entries,
  bool backendConfigured = true,
  double textScale = 1,
  Brightness phoneBrightness = Brightness.dark,
}) async {
  useScreen(tester, size: const Size(360, 1600), textScale: textScale);
  final catalog = FakeCatalogRepository(
    entries: entries ?? _samples,
    lyrics: BundledLyricsRepository(DiskAssetBundle()),
  );
  await pumpZemaApp(
    tester,
    libraryScanner: FakeLibraryScanner([
      scannedAudio(1, '/m/1.mp3', title: 'Amlak'),
    ]),
    database: memoryDatabase(),
    catalog: catalog,
    backendConfigured: backendConfigured,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  await _settle(tester);
  return catalog;
}

Finder get _row => find.byType(CommunityLyricsRow);

/// The row's card titles, left to right.
List<String> _titles(WidgetTester tester) {
  final cards = find.descendant(of: _row, matching: find.byType(InkWell));
  return [
    for (final card in cards.evaluate())
      (find
                  .descendant(
                    of: find.byWidget(card.widget),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .elementAt(2)
                  .widget
              as Text)
          .data!,
  ];
}

Finder _card(String title) => find.ancestor(
  of: find.descendant(of: _row, matching: find.text(title)),
  matching: find.byType(InkWell),
);

Finder _inCard(String title, String text) =>
    find.descendant(of: _card(title), matching: find.text(text));

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

void main() {
  testWidgets('the newest songs first, each with Synced or Text only', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.descendant(of: _row, matching: find.text(_l10n.homeNewLyrics)),
      findsOneWidget,
    );
    expect(_titles(tester), ['Galatoomi', 'ሰላም ለዚህ ቤት', 'ብርሃን ሆንልን']);
    expect(_inCard('Galatoomi', _l10n.songRecordingSynced), findsOneWidget);
    expect(_inCard('Galatoomi', 'Zema Samples'), findsOneWidget);
    expect(_inCard('ሰላም ለዚህ ቤት', _l10n.songRecordingTextOnly), findsOneWidget);
    expect(_inCard('ሰላም ለዚህ ቤት', _l10n.songRecordingSynced), findsNothing);
  });

  testWidgets('at most 10 songs; the same day sorts by title', (tester) async {
    await _pump(
      tester,
      entries: [
        for (var i = 1; i <= 12; i++) _entry('s$i', 'Song $i', day: i),
        // Listed after s12 in the index (by ID), but its title sorts first.
        _entry('z', 'B same day', day: 12),
      ],
    );

    expect(_titles(tester), [
      'B same day',
      'Song 12',
      for (var i = 11; i >= 4; i--) 'Song $i',
    ]);
  });

  testWidgets('a card opens Song detail in the Home tab; Back returns', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_card('Galatoomi'));
    await _settle(tester);

    expect(find.byType(SongDetailScreen), findsOneWidget);
    expect(_location(tester), '/home/song?id=galatoomi');

    await tester.pageBack();
    await _settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_row, findsOneWidget);
  });

  testWidgets('an empty index hides the row', (tester) async {
    await _pump(tester, entries: const []);

    expect(find.text(_l10n.homeNewLyrics), findsNothing);
  });

  testWidgets('a build with no backend has no row', (tester) async {
    await _pump(tester, backendConfigured: false);

    expect(find.text(_l10n.homeNewLyrics), findsNothing);
  });

  testWidgets('an index refresh updates the row in place', (tester) async {
    final catalog = await _pump(tester);
    catalog.entries = [
      ..._samples,
      _entry('new', 'Brand new', day: 28, synced: false),
    ];

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await tester.runAsync(
      () => container.read(catalogIndexRefresherProvider).refresh(force: true),
    );
    await _settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_titles(tester).first, 'Brand new');
    expect(_inCard('Brand new', _l10n.songRecordingTextOnly), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits at 1.3× text in ${brightness.name} mode', (tester) async {
      await _pump(
        tester,
        entries: [
          _entry(
            'long',
            'A very long song title that keeps going past the card',
            day: 1,
            synced: false,
            artist: 'Addis Ababa Holy Trinity Cathedral Choir',
          ),
          ..._samples,
        ],
        textScale: 1.3,
        phoneBrightness: brightness,
      );

      expect(_row, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
