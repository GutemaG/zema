import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema_admin/src/app.dart';
import 'package:zema_admin/src/catalog_page.dart';
import 'package:zema_admin/src/reports_page.dart';
import 'package:zema_admin/src/session.dart';
import 'package:zema_admin/src/strings.dart';
import 'package:zema_core/zema_core.dart';

final _now = DateTime.now();

ModeratorReport _report(
  String id, {
  ReportStatus status = ReportStatus.open,
  String? songId = 'selam',
}) => ModeratorReport(
  id: id,
  songId: songId,
  songTitle: songId == null ? null : 'Selam',
  reason: ReportReason.wrongWords,
  note: 'Line 2 is wrong',
  status: status,
  createdAt: _now.subtract(const Duration(hours: 2)),
);

ModeratedSong _song(String id, {bool hidden = false}) => ModeratedSong(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  hidden: hidden,
  version: 2,
  lineCount: 1,
  updatedAt: _now,
);

class _Repository implements ModerationRepository {
  List<ModeratorReport> reportList = [
    _report('r1'),
    _report('r2', status: ReportStatus.resolved, songId: null),
  ];
  final statuses = <ReportStatus?>[];
  final closed = <(String, ReportStatus)>[];
  List<ModeratedSong> songList = [_song('selam'), _song('fikir', hidden: true)];
  final queries = <(String, int)>[];
  final hiddenChanges = <(String, bool)>[];

  @override
  Future<List<ModeratorReport>> reports(
    ReportStatus? status, {
    int limit = 100,
    int offset = 0,
  }) async {
    statuses.add(status);
    return [
      for (final r in reportList)
        if (status == null || r.status == status) r,
    ];
  }

  @override
  Future<void> resolveReport(String id, ReportStatus status) async {
    closed.add((id, status));
    reportList = [
      for (final r in reportList)
        r.id == id ? _report(id, status: status, songId: r.songId) : r,
    ];
  }

  @override
  Future<List<ModeratedSong>> songs({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    queries.add((query, limit));
    return [
      for (final s in songList)
        if (s.id.contains(query)) s,
    ];
  }

  @override
  Future<SongDocument?> song(String id) async => SongDocument(
    song: Song(
      id: id,
      title: 'Song $id',
      sections: const [
        LyricSection(
          id: 'v',
          kind: SectionKind.verse,
          lines: [LyricLine('the only line')],
        ),
      ],
    ),
    recordings: [
      Recording(id: 'rec-$id', songId: id, source: RecordingSource.localFile),
    ],
  );

  @override
  Future<void> setHidden(String id, {required bool hidden}) async {
    hiddenChanges.add((id, hidden));
    songList = [
      for (final s in songList) s.id == id ? _song(id, hidden: hidden) : s,
    ];
  }
}

void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUp(() => repository = _Repository());

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: [moderationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('reports', () {
    testWidgets('open ones first; the others by filter', (tester) async {
      await pump(tester, const ReportsPage());
      expect(repository.statuses.single, ReportStatus.open);
      expect(find.text('Selam'), findsOneWidget);
      expect(find.textContaining(Strings.wrongWords), findsOneWidget);
      expect(find.text('Line 2 is wrong'), findsOneWidget);

      await tester.tap(find.text(Strings.all));
      await tester.pumpAndSettle();
      expect(repository.statuses.last, isNull);
      expect(find.text(Strings.songRemoved), findsOneWidget);
    });

    testWidgets('resolve one: it leaves the open list', (tester) async {
      await pump(tester, const ReportsPage());
      await tester.tap(find.text(Strings.resolve));
      await tester.pumpAndSettle();
      expect(repository.closed, [('r1', ReportStatus.resolved)]);
      expect(find.text(Strings.reportsEmpty), findsOneWidget);
    });

    testWidgets('dismiss one', (tester) async {
      await pump(tester, const ReportsPage());
      await tester.tap(find.text(Strings.dismiss));
      await tester.pumpAndSettle();
      expect(repository.closed, [('r1', ReportStatus.dismissed)]);
    });

    testWidgets('Open song goes to the song in the catalog', (tester) async {
      await pump(tester, const ReportsPage());
      await tester.tap(find.text(Strings.openSong));
      await tester.pumpAndSettle();
      expect(container.read(adminPageProvider), AdminPage.catalog);
      expect(container.read(catalogQueryProvider), 'selam');
      expect(container.read(selectedSongProvider), 'selam');
    });
  });

  group('catalog', () {
    testWidgets('search, then a song with its lyrics', (tester) async {
      await pump(tester, const CatalogPage());
      expect(find.text('Song selam'), findsOneWidget);
      expect(find.text(Strings.hidden), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'fik');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repository.queries.last, ('fik', 50));
      expect(find.text('Song selam'), findsNothing);

      await tester.tap(find.text('Song fikir'));
      await tester.pumpAndSettle();
      expect(find.text('the only line'), findsOneWidget);
      expect(find.text(Strings.notSynced), findsOneWidget);
      expect(find.text(Strings.restore), findsOneWidget);
    });

    testWidgets('hide asks first, then hides', (tester) async {
      await pump(tester, const CatalogPage());
      await tester.tap(find.text('Song selam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.hide));
      await tester.pumpAndSettle();
      expect(find.text(Strings.hideTitle), findsOneWidget);
      await tester.tap(find.text(Strings.cancel));
      await tester.pumpAndSettle();
      expect(repository.hiddenChanges, isEmpty);

      await tester.tap(find.text(Strings.hide));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, Strings.hide));
      await tester.pumpAndSettle();
      expect(repository.hiddenChanges, [('selam', true)]);
      expect(find.text(Strings.songHidden), findsOneWidget);
      expect(find.text(Strings.restore), findsOneWidget);
    });

    testWidgets('restore needs no confirmation', (tester) async {
      await pump(tester, const CatalogPage());
      await tester.tap(find.text('Song fikir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.restore));
      await tester.pumpAndSettle();
      expect(repository.hiddenChanges, [('fikir', false)]);
      expect(find.text(Strings.songRestored), findsOneWidget);
    });

    testWidgets('a full page offers more', (tester) async {
      repository.songList = [for (var i = 0; i < 50; i++) _song('s$i')];
      await pump(tester, const CatalogPage());
      await tester.scrollUntilVisible(
        find.text(Strings.loadMore),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text(Strings.loadMore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.loadMore));
      await tester.pumpAndSettle();
      expect(repository.queries.last, ('', 100));
    });
  });
}
