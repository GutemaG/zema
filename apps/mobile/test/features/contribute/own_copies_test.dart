import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/contribute/application/own_copies.dart';
import 'package:zema/features/lyrics/data/lyrics_links_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

const _song = Song(
  id: 'selam',
  title: 'Selam',
  sections: [
    LyricSection(id: 'v1', kind: SectionKind.verse, lines: [LyricLine('One')]),
  ],
  playOrder: ['v1'],
);

OwnCopy _copy(String id, {int? trackId, String? audioPath}) => OwnCopy(
  contributionId: id,
  kind: ContributionKind.newSong,
  song: _song,
  trackId: trackId,
  audioPath: audioPath,
  submittedAt: DateTime.utc(2026, 11, 2, 9),
);

SubmittedContribution _reviewed(
  String id,
  ContributionStatus status, {
  String? songId,
}) => SubmittedContribution(
  id: id,
  contribution: const Contribution.newSong(_song),
  status: status,
  songId: songId,
  createdAt: DateTime.utc(2026, 11, 2, 9),
  submittedAt: DateTime.utc(2026, 11, 2, 9),
);

void main() {
  late ZemaDatabase db;
  late LyricsLinksRepository links;
  late OwnCopyReconciler reconciler;
  late Directory files;
  late int track;

  setUp(() async {
    db = memoryDatabase();
    links = LyricsLinksRepository(db.lyricsLinksDao);
    reconciler = OwnCopyReconciler(db.ownCopiesDao, links);
    files = await Directory.systemTemp.createTemp('own_copies');
    final library = db.libraryDao;
    await library.applyReconciliation(
      reconcileTracks(
        stored: const [],
        scan: [scannedAudio(1, '/m/Selam.mp3', title: 'Selam')],
      ),
    );
    track = (await library.allTracks()).single.id;
  });
  tearDown(() async {
    await db.close();
    await files.delete(recursive: true);
  });

  Future<File> sharedFile(String name) async {
    final file = File('${files.path}/shared_audio/$name');
    await file.create(recursive: true);
    return file;
  }

  Future<Map<int, LyricsLink>> currentLinks() async => links.watchLinks().first;

  test('approved: the track shows the catalog song the copy became, and '
      'the copy and its shared file go', () async {
    final audio = await sharedFile('a.ogg');
    await db.ownCopiesDao.add(
      _copy('a', trackId: track, audioPath: audio.path),
    );

    final removed = await reconciler.reconcile([
      _reviewed('a', ContributionStatus.approved, songId: 'selam-2'),
    ]);

    expect(removed, ['a']);
    expect(await db.ownCopiesDao.all(), isEmpty);
    final link = (await currentLinks())[track]!;
    expect(link.songId, 'selam-2', reason: 'the id it became');
    expect(link.manual, isTrue, reason: 'automatic matching keeps it');
    expect(audio.existsSync(), isFalse);
  });

  test('approved without a song id uses the proposed one', () async {
    await db.ownCopiesDao.add(_copy('a', trackId: track));
    await reconciler.reconcile([_reviewed('a', ContributionStatus.approved)]);
    expect((await currentLinks())[track]!.songId, 'selam');
  });

  test('rejected: the copy and its shared file go, and the track keeps '
      'what it had', () async {
    await links.setManual(track, 'old-song');
    final audio = await sharedFile('b.ogg');
    await db.ownCopiesDao.add(
      _copy('b', trackId: track, audioPath: audio.path),
    );

    expect(
      await reconciler.reconcile([_reviewed('b', ContributionStatus.rejected)]),
      ['b'],
    );

    expect(await db.ownCopiesDao.all(), isEmpty);
    expect((await currentLinks())[track]!.songId, 'old-song');
    expect(audio.existsSync(), isFalse);
  });

  test('pending, changes requested and unknown ones stay', () async {
    final audio = await sharedFile('c.ogg');
    await db.ownCopiesDao.add(_copy('p', trackId: track));
    await db.ownCopiesDao.add(_copy('c', audioPath: audio.path));
    await db.ownCopiesDao.add(_copy('x'));

    expect(
      await reconciler.reconcile([
        _reviewed('p', ContributionStatus.pending),
        _reviewed('c', ContributionStatus.changesRequested),
        _reviewed('other', ContributionStatus.approved, songId: 'z'),
      ]),
      isEmpty,
    );

    expect(await db.ownCopiesDao.all(), hasLength(3));
    expect(await currentLinks(), isEmpty);
    expect(audio.existsSync(), isTrue);
  });

  test('an approved copy with no track only goes', () async {
    await db.ownCopiesDao.add(_copy('a'));
    await reconciler.reconcile([
      _reviewed('a', ContributionStatus.approved, songId: 'selam'),
    ]);
    expect(await db.ownCopiesDao.all(), isEmpty);
    expect(await currentLinks(), isEmpty);
  });
}
