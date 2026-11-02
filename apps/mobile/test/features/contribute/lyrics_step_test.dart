import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

LyricSection block(String id, SectionKind kind, List<String> lines) =>
    LyricSection(
      id: id,
      kind: kind,
      lines: [for (final l in lines) LyricLine(l)],
    );

ContributionDraft draftOf(List<LyricSection> sections, {List<String>? order}) =>
    ContributionDraft(
      song: Song(
        id: '',
        title: 'Selam',
        sections: sections,
        playOrder: order ?? [for (final s in sections) s.id],
      ),
    );

void main() {
  group('helpers', () {
    test('labels number verses always, other kinds only when repeated', () {
      final sections = [
        block('v1', SectionKind.verse, ['a']),
        block('c1', SectionKind.chorus, ['b']),
        block('b1', SectionKind.bridge, ['c']),
        block('b2', SectionKind.bridge, ['d']),
      ];
      expect(
        [for (final s in sections) sectionLabel(_l10n, sections, s)],
        ['Verse 1', 'Chorus', 'Bridge 1', 'Bridge 2'],
      );
    });

    test('new ids are the first unused for the kind', () {
      final sections = [
        block('v1', SectionKind.verse, ['a']),
        block('v3', SectionKind.verse, ['b']),
      ];
      expect(newSectionId(sections, SectionKind.verse), 'v2');
      expect(newSectionId(sections, SectionKind.chorus), 'c1');
      expect(newSectionId(sections, SectionKind.other), 'o1');
    });

    test('lines: one per row, trailing empty rows dropped, Latin by row', () {
      expect(linesFromText('one \ntwo\n\n', 'wan\n\nextra'), const [
        LyricLine('one', transliteration: 'wan'),
        LyricLine('two'),
      ]);
      expect(linesFromText('one\n\nthree', ''), const [
        LyricLine('one'),
        LyricLine(''),
        LyricLine('three'),
      ]);
    });
  });

  late ZemaDatabase db;

  setUp(() => db = memoryDatabase());

  Future<int> open(
    WidgetTester tester, {
    ContributionDraft draft = const ContributionDraft(),
    Size size = const Size(400, 2400),
    double textScale = 1,
    Brightness brightness = Brightness.dark,
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    final id = await db.draftsDao.create(draft, now: DateTime.utc(2026, 11, 2));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    await pumpZemaApp(
      tester,
      location: AppRoutes.draft(id),
      auth: FakeAuthRepository(user: testUser),
      database: db,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
    );
    return id;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<ContributionDraft> saved(WidgetTester tester) async {
    await tester.pump(draftSaveDelay * 2);
    final row = (await db.select(db.drafts).get()).single;
    return ContributionDraft.fromJson(jsonDecode(row.draft));
  }

  Finder blockFields() => find.byWidgetPredicate(
    (w) =>
        w is TextField && w.decoration?.hintText == _l10n.contributeBlockHint,
  );

  Finder next() =>
      find.widgetWithText(FilledButton, _l10n.contributeNextRecording);

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(next()).onPressed != null;

  Future<void> blockMenu(WidgetTester tester, int i, String item) async {
    await tap(tester, find.byTooltip(_l10n.contributeBlockMenu).at(i));
    await tap(tester, find.text(item).last);
  }

  Future<void> entryMenu(WidgetTester tester, int n, String item) async {
    await tap(tester, find.byTooltip(_l10n.contributePlayOrderEntry(n)));
    await tap(tester, find.text(item).last);
  }

  testWidgets('shows the details, the hint and the step strip', (tester) async {
    await open(tester);
    expect(find.text(_l10n.contributeFieldTitle), findsOneWidget);
    expect(find.text(_l10n.contributeFieldAlbum), findsOneWidget);
    expect(find.text(_l10n.contributeChorusHint), findsOneWidget);
    expect(find.text(_l10n.contributeStepSync), findsOneWidget);
    expect(find.text(_l10n.contributeAddBlock), findsOneWidget);
    expect(find.text(_l10n.contributePlayOrder.toUpperCase()), findsNothing);
  });

  testWidgets('blocks are added, typed and given a kind; the play order '
      'follows them', (tester) async {
    await open(tester);
    await tap(tester, find.text(_l10n.contributeAddBlock));
    await tap(tester, find.text(_l10n.contributeAddBlock));
    await tester.enterText(blockFields().at(0), 'ሰላም\nለዚህ ቤት');
    await tester.enterText(blockFields().at(1), 'Chorus line');
    await tester.pump();

    await tap(tester, find.byTooltip(_l10n.contributeBlockKind).at(1));
    await tap(tester, find.text(_l10n.lyricsChorus).last);

    final draft = await saved(tester);
    expect(draft.song.sections, [
      block('v1', SectionKind.verse, ['ሰላም', 'ለዚህ ቤት']),
      block('v2', SectionKind.chorus, ['Chorus line']),
    ]);
    expect(draft.song.playOrder, ['v1', 'v2']);
    expect(find.text('CHORUS'), findsOneWidget);
    expect(find.text('Verse 1'), findsOneWidget, reason: 'in the play order');
  });

  testWidgets('moving a block keeps the default play order in step', (
    tester,
  ) async {
    await open(
      tester,
      draft: draftOf([
        block('v1', SectionKind.verse, ['a']),
        block('c1', SectionKind.chorus, ['b']),
      ]),
    );
    await blockMenu(tester, 0, _l10n.contributeBlockMoveDown);
    final draft = await saved(tester);
    expect([for (final s in draft.song.sections) s.id], ['c1', 'v1']);
    expect(draft.song.playOrder, ['c1', 'v1']);
  });

  testWidgets('play order entries are added, moved and removed', (
    tester,
  ) async {
    await open(
      tester,
      draft: draftOf([
        block('v1', SectionKind.verse, ['a']),
        block('c1', SectionKind.chorus, ['b']),
        block('v2', SectionKind.verse, ['c']),
      ]),
    );
    await tap(tester, find.byTooltip(_l10n.contributePlayOrderAdd));
    await tap(tester, find.text(_l10n.lyricsChorus).last);
    expect((await saved(tester)).song.playOrder, ['v1', 'c1', 'v2', 'c1']);

    await entryMenu(tester, 3, _l10n.contributePlayOrderEarlier);
    expect((await saved(tester)).song.playOrder, ['v1', 'v2', 'c1', 'c1']);

    await entryMenu(tester, 1, _l10n.contributePlayOrderLater);
    expect((await saved(tester)).song.playOrder, ['v2', 'v1', 'c1', 'c1']);

    await entryMenu(tester, 4, _l10n.contributePlayOrderRemove);
    expect((await saved(tester)).song.playOrder, ['v2', 'v1', 'c1']);

    // A custom order no longer follows new blocks.
    await tap(tester, find.text(_l10n.contributeAddBlock));
    expect((await saved(tester)).song.playOrder, ['v2', 'v1', 'c1']);
  });

  testWidgets('deleting a block in the play order asks, then removes its '
      'entries', (tester) async {
    await open(
      tester,
      draft: draftOf(
        [
          block('v1', SectionKind.verse, ['a']),
          block('c1', SectionKind.chorus, ['b']),
        ],
        order: ['v1', 'c1', 'v1', 'c1'],
      ),
    );
    await blockMenu(tester, 1, _l10n.contributeBlockDelete);
    expect(find.text(_l10n.contributeBlockDeleteMessage(2)), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(_l10n.actionCancel),
      ),
    );
    expect((await saved(tester)).song.sections, hasLength(2));

    await blockMenu(tester, 1, _l10n.contributeBlockDelete);
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(_l10n.contributeBlockDelete),
      ),
    );
    final draft = await saved(tester);
    expect([for (final s in draft.song.sections) s.id], ['v1']);
    expect(draft.song.playOrder, ['v1', 'v1']);
  });

  testWidgets('an empty block is deleted without asking', (tester) async {
    await open(tester);
    await tap(tester, find.text(_l10n.contributeAddBlock));
    await blockMenu(tester, 0, _l10n.contributeBlockDelete);
    expect(find.byType(AlertDialog), findsNothing);
    final draft = await saved(tester);
    expect(draft.song.sections, isEmpty);
    expect(draft.song.playOrder, isEmpty);
  });

  testWidgets('Paste all text makes the blocks and play order', (tester) async {
    await open(tester);
    await tap(tester, find.text(_l10n.contributePasteAll));
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Verse one\nline two\n\nThe chorus\n\nVerse two\n\nThe chorus',
    );
    await tap(tester, find.text(_l10n.contributePasteSplit));

    final draft = await saved(tester);
    final pasted = splitPastedLyrics(
      'Verse one\nline two\n\nThe chorus\n\nVerse two\n\nThe chorus',
    );
    expect(draft.song.sections, pasted.sections);
    expect(draft.song.playOrder, ['v1', 'c1', 'v2', 'c1']);
    expect(find.text(_l10n.contributePasted(3)), findsOneWidget);
    expect(
      tester.widget<TextField>(blockFields().at(0)).controller!.text,
      'Verse one\nline two',
    );

    // And it can be changed afterwards.
    await tester.enterText(blockFields().at(2), 'Verse two, fixed');
    expect(
      (await saved(tester)).song.sections[2].lines.single.text,
      'Verse two, fixed',
    );
  });

  testWidgets('pasting over blocks says it replaces them', (tester) async {
    await open(
      tester,
      draft: draftOf([
        block('v1', SectionKind.verse, ['a']),
      ]),
    );
    await tap(tester, find.text(_l10n.contributePasteAll));
    expect(find.textContaining(_l10n.contributePasteReplaces), findsOneWidget);
    await tap(tester, find.text(_l10n.actionCancel));
    expect((await saved(tester)).song.sections, hasLength(1));
  });

  testWidgets('each line can have Latin letters', (tester) async {
    await open(
      tester,
      draft: draftOf([
        block('v1', SectionKind.verse, ['ሰላም', 'ቤት']),
      ]),
    );
    await blockMenu(tester, 0, _l10n.contributeBlockShowLatin);
    await tester.enterText(
      find.widgetWithText(TextField, _l10n.contributeBlockLatin),
      'Selam\nBet',
    );
    final lines = (await saved(tester)).song.sections.single.lines;
    expect(lines, const [
      LyricLine('ሰላም', transliteration: 'Selam'),
      LyricLine('ቤት', transliteration: 'Bet'),
    ]);
  });

  testWidgets('Next stays off until the lyrics are valid, then goes on', (
    tester,
  ) async {
    await open(tester, draft: const ContributionDraft());
    expect(nextEnabled(tester), isFalse, reason: 'nothing typed');

    await tester.enterText(
      find.widgetWithText(TextField, _l10n.contributeFieldTitle),
      'Selam',
    );
    await tap(tester, find.text(_l10n.contributeAddBlock));
    expect(nextEnabled(tester), isFalse, reason: 'an empty block');

    await tester.enterText(blockFields().first, 'one\n\nthree');
    await tester.pump();
    expect(nextEnabled(tester), isFalse);
    expect(find.text(_l10n.contributeBlockBlankLine), findsOneWidget);

    await tester.enterText(blockFields().first, 'one\nthree');
    await tester.pump();
    expect(find.text(_l10n.contributeBlockBlankLine), findsNothing);
    expect(nextEnabled(tester), isTrue);

    await entryMenu(tester, 1, _l10n.contributePlayOrderRemove);
    expect(nextEnabled(tester), isFalse);
    expect(find.text(_l10n.contributePlayOrderEmpty), findsOneWidget);

    await tap(tester, find.byTooltip(_l10n.contributePlayOrderAdd));
    await tap(tester, find.text('Verse 1').last);
    await tap(tester, next());
    expect((await saved(tester)).step, DraftStep.recording);
  });

  testWidgets('a line over the limit is flagged', (tester) async {
    await open(
      tester,
      draft: draftOf([
        block('v1', SectionKind.verse, ['a']),
      ]),
    );
    await tester.enterText(blockFields().first, 'x' * (maxLineLength + 1));
    await tester.pump();
    expect(
      find.text(_l10n.contributeLineTooLong(maxLineLength)),
      findsOneWidget,
    );
    expect(nextEnabled(tester), isFalse);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      await open(
        tester,
        size: const Size(360, 640),
        textScale: 1.3,
        brightness: brightness,
        draft: draftOf(
          [
            block('v1', SectionKind.verse, ['እግዚአብሔርን አመስግኑ ቸር ነውና ' * 3]),
            block('c1', SectionKind.chorus, ['ምሕረቱ ለዘላለም ነውና']),
            block('b1', SectionKind.bridge, ['b']),
            block('b2', SectionKind.bridge, ['b']),
            block('o1', SectionKind.other, ['o']),
          ],
          order: ['v1', 'c1', 'b1', 'c1', 'b2', 'c1', 'o1', 'c1'],
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byTooltip(_l10n.contributePlayOrderAdd),
        200,
        // The list, not a block's own text field.
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tap(tester, find.byTooltip(_l10n.contributeBlockMenu).last);
      expect(tester.takeException(), isNull);
    });
  }
}
