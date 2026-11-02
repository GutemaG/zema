import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart' hide TrackRow;
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/song_info_screen.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/library/presentation/widgets/track_selection_bar.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late ZemaDatabase db;
  late FakeCoverStore covers;

  setUp(() {
    db = memoryDatabase();
    covers = FakeCoverStore();
  });

  Future<void> open(WidgetTester tester) async {
    useScreen(tester, size: const Size(400, 900));
    await pumpZemaApp(
      tester,
      location: AppRoutes.library,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/m/1.mp3', title: 'Amlak', artist: 'Choir'),
        scannedAudio(2, '/m/2.mp3', title: 'Kidus'),
      ]),
      database: db,
      covers: covers,
      savedPrefs: {LibraryAccessController.explainedKey: true},
    );
  }

  Finder row(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(TrackRow));

  List<String> titles(WidgetTester tester) => [
    for (final r in tester.widgetList<TrackRow>(find.byType(TrackRow)))
      r.track.title,
  ];

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester, String title) async {
    await tester.longPress(row(title));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TrackSelectionBar),
        matching: find.byTooltip(_l10n.songInfoTitle),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SongInfoScreen), findsOneWidget);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('saved edits show and sort in the library; the file is left '
      'alone', (tester) async {
    await open(tester);
    expect(titles(tester), ['Amlak', 'Kidus']);
    await openEditor(tester, 'Kidus');
    await tester.enterText(field(_l10n.songInfoFieldTitle), 'Abba Kidus');
    await tester.enterText(field(_l10n.songInfoFieldArtist), 'New choir');
    await tester.enterText(field(_l10n.songInfoFieldTrackNumber), '4x2');
    await tap(tester, find.text(_l10n.actionSave));
    expect(find.text(_l10n.songInfoSaved), findsOneWidget);
    expect(titles(tester), ['Abba Kidus', 'Amlak']);
    final edit = (await db.select(db.trackOverrides).get()).single;
    expect(edit.title, 'Abba Kidus');
    expect(edit.artist, 'New choir');
    expect(edit.trackNumber, 42, reason: 'digits only');
    expect(edit.album, isNull, reason: 'unchanged fields keep the file');
    final file = (await db.select(db.tracks).get()).firstWhere(
      (t) => t.mediaStoreId == 2,
    );
    expect(file.title, 'Kidus');
  });

  testWidgets('an empty title is not saved', (tester) async {
    await open(tester);
    await openEditor(tester, 'Amlak');
    await tester.enterText(field(_l10n.songInfoFieldTitle), '   ');
    await tap(tester, find.text(_l10n.actionSave));
    expect(find.text(_l10n.songInfoTitleRequired), findsOneWidget);
    expect(find.byType(SongInfoScreen), findsOneWidget);
    expect(await db.select(db.trackOverrides).get(), isEmpty);
  });

  testWidgets('a picked cover is kept; Reset forgets edits and cover', (
    tester,
  ) async {
    await open(tester);
    await openEditor(tester, 'Amlak');
    await tap(tester, find.text(_l10n.songInfoChooseCover));
    await tap(tester, find.text(_l10n.songInfoChooseCover));
    expect(covers.deleted, ['cover-1-1.jpg'], reason: 'replaced unsaved');
    await tap(tester, find.text(_l10n.actionSave));
    expect(
      (await db.select(db.trackOverrides).get()).single.coverPath,
      'cover-1-2.jpg',
    );
    expect(titles(tester), ['Amlak', 'Kidus'], reason: 'only the cover');
    // Past the "saved" message, so the next one shows.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await openEditor(tester, 'Amlak');
    await tap(tester, find.text(_l10n.songInfoReset));
    expect(find.text(_l10n.songInfoResetDone), findsOneWidget);
    expect(await db.select(db.trackOverrides).get(), isEmpty);
    expect(covers.deleted, contains('cover-1-2.jpg'));
  });

  testWidgets('saving what the file says keeps no edit', (tester) async {
    await open(tester);
    await openEditor(tester, 'Amlak');
    await tester.enterText(field(_l10n.songInfoFieldArtist), ' Choir ');
    await tap(tester, find.text(_l10n.actionSave));
    expect(await db.select(db.trackOverrides).get(), isEmpty);
  });
}
