import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

const _song = Song(
  id: 'selam',
  title: 'Selam',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('One'), LyricLine('Two')],
    ),
  ],
  playOrder: ['v1'],
);

OwnCopy copy(
  String id, {
  int? trackId,
  String? audioPath,
  DateTime? at,
  SyncTiming? timing,
}) => OwnCopy(
  contributionId: id,
  kind: ContributionKind.newSong,
  song: _song,
  recording: const Recording(
    id: 'rec-1',
    songId: 'selam',
    source: RecordingSource.localFile,
    fileName: 'Selam.mp3',
  ),
  timing: timing,
  trackId: trackId,
  audioPath: audioPath,
  submittedAt: at ?? DateTime.utc(2026, 11, 2, 9),
);

void main() {
  late ZemaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('keeps the whole copy, last sent first', () async {
    final dao = db.ownCopiesDao;
    const timing = SyncTiming(
      recordingId: 'rec-1',
      starts: [Duration(seconds: 1), Duration(seconds: 3)],
    );
    await dao.add(copy('a', trackId: 7, timing: timing));
    await dao.add(
      copy(
        'b',
        audioPath: '/files/shared_audio/b.ogg',
        at: DateTime.utc(2026, 11, 2, 10),
      ),
    );

    final all = await dao.all();
    expect(all.map((c) => c.contributionId), ['b', 'a']);
    final a = all.last;
    expect(a.kind, ContributionKind.newSong);
    expect(a.song, _song);
    expect(a.recording?.fileName, 'Selam.mp3');
    expect(a.timing, timing);
    expect(a.trackId, 7);
    expect(a.submittedAt, DateTime.utc(2026, 11, 2, 9));
    expect(all.first.timing, isNull);
    expect(await dao.audioPaths(), ['/files/shared_audio/b.ogg']);
  });

  test('the same contribution again replaces its copy', () async {
    final dao = db.ownCopiesDao;
    await dao.add(copy('a', trackId: 7));
    await dao.add(copy('a', trackId: 8));
    expect((await dao.all()).single.trackId, 8);
  });

  test('remove and clear', () async {
    final dao = db.ownCopiesDao;
    await dao.add(copy('a'));
    await dao.add(copy('b'));
    await dao.remove('a');
    expect((await dao.all()).single.contributionId, 'b');
    await dao.clear();
    expect(await dao.all(), isEmpty);
  });

  test('a copy this app cannot read is left out', () async {
    final dao = db.ownCopiesDao;
    await dao.add(copy('a'));
    await db.customStatement("UPDATE own_copies SET song = '{}'");
    expect(await dao.all(), isEmpty);
  });
}
