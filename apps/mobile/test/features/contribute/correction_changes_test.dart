import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/app/theme/zema_theme.dart';
import 'package:zema/features/contribute/presentation/correction_changes.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Three sung lines: a verse of two, then its chorus.
const base = Song(
  id: 'selam',
  title: 'Selam',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('Selam lezih bet'), LyricLine('Selam lekulu')],
    ),
    LyricSection(
      id: 'c1',
      kind: SectionKind.chorus,
      lines: [LyricLine('Haleluya')],
    ),
  ],
  playOrder: ['v1', 'c1'],
);

Song edited(List<LyricSection> sections) => Song(
  id: base.id,
  title: base.title,
  sections: sections,
  playOrder: [for (final s in sections) s.id],
);

const choir = Recording(
  id: 'rec-1',
  songId: 'selam',
  source: RecordingSource.youtube,
  artist: 'Choir',
  duration: Duration(minutes: 3, seconds: 7),
);
const plain = Recording(
  id: 'rec-2',
  songId: 'selam',
  source: RecordingSource.youtube,
  artist: 'Deacon',
);
final timings = [
  SyncTiming(
    recordingId: choir.id,
    starts: const [Duration.zero, Duration(seconds: 2), Duration(seconds: 4)],
  ),
];

Future<void> pump(
  WidgetTester tester,
  Song song, {
  Brightness brightness = Brightness.dark,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildTheme(ZemaPalette.fallback, brightness),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CorrectionChanges(
          base: base,
          edited: song,
          recordings: const [choir, plain],
          timings: timings,
        ),
      ),
    ),
  ),
);

/// A typo fixed, two lines added to the verse and the chorus deleted: four
/// sung lines instead of three.
final _bigEdit = edited(const [
  LyricSection(
    id: 'v1',
    kind: SectionKind.verse,
    lines: [
      LyricLine('Selam lezih bet'),
      LyricLine('Selam lekullu'),
      LyricLine('Amen amen amen amen amen amen amen amen amen'),
      LyricLine('Amen'),
    ],
  ),
]);

void main() {
  testWidgets('no change says so, and no recording loses its timing', (
    tester,
  ) async {
    await pump(tester, base);
    expect(find.text(_l10n.contributeCorrectionNoChanges), findsOneWidget);
    expect(find.text(_l10n.contributeCorrectionLosesTimings), findsNothing);
  });

  testWidgets('a fixed typo shows the old and new line; timings stay', (
    tester,
  ) async {
    await pump(
      tester,
      edited(const [
        LyricSection(
          id: 'v1',
          kind: SectionKind.verse,
          lines: [LyricLine('Selam lezih bet'), LyricLine('Selam lekullu')],
        ),
        LyricSection(
          id: 'c1',
          kind: SectionKind.chorus,
          lines: [LyricLine('Haleluya')],
        ),
      ]),
    );
    expect(
      find.text('${_l10n.contributeCorrectionChanged} · Verse 1'),
      findsOneWidget,
    );
    final old = tester.widget<Text>(find.text('Selam lekulu'));
    expect(old.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('Selam lekullu'), findsOneWidget);
    expect(find.text('Selam lezih bet'), findsNothing, reason: 'unchanged');
    expect(find.text(_l10n.contributeCorrectionNoChanges), findsNothing);
    expect(find.text(_l10n.contributeCorrectionLosesTimings), findsNothing);
  });

  testWidgets('added and removed lines, and the recording that loses its '
      'timing is named', (tester) async {
    await pump(tester, _bigEdit);
    expect(
      find.text('${_l10n.contributeCorrectionAdded} · Verse 1'),
      findsNWidgets(2),
    );
    expect(
      find.text('${_l10n.contributeCorrectionRemoved} · Chorus'),
      findsOneWidget,
    );
    expect(find.text('Haleluya'), findsOneWidget);
    expect(find.text(_l10n.contributeCorrectionLosesTimings), findsOneWidget);
    expect(find.text('Choir · 3:07'), findsOneWidget);
    expect(find.textContaining('Deacon'), findsNothing, reason: 'not synced');
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      await pump(tester, _bigEdit, brightness: brightness);
      expect(tester.takeException(), isNull);
      expect(find.text('Choir · 3:07'), findsOneWidget);
    });
  }
}
