import 'dart:convert';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const lyrics = Song(
  id: '',
  title: '  ሰላም ለዚህ ቤት ',
  transliteration: 'Selam Lezih Bet',
  artist: '  ',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('a'), LyricLine('b')],
    ),
  ],
  playOrder: ['v1'],
);

const local = Recording(
  id: 'rec-1',
  songId: '',
  source: RecordingSource.localFile,
  artist: ' Choir ',
  duration: Duration(minutes: 3),
  fileName: 'Selam.mp3',
);

ContributionDraft roundTrip(ContributionDraft d) =>
    ContributionDraft.fromJson(jsonDecode(jsonEncode(d.toJson())));

void main() {
  group('JSON', () {
    test('an empty new draft', () {
      const draft = ContributionDraft();
      expect(roundTrip(draft), draft);
      expect(draft.title, '');
      expect(draft.step, DraftStep.lyrics);
    });

    test('everything, including starts not tapped yet', () {
      const draft = ContributionDraft(
        kind: ContributionKind.editLyrics,
        songId: 'selam-lezih-bet',
        baseVersion: 4,
        song: lyrics,
        recording: local,
        starts: [Duration(seconds: 1), null],
        trackId: 12,
        audioPath: '/data/shared_audio/1-Selam.ogg',
        videoTitle: 'Selam (live)',
        step: DraftStep.sync,
      );
      expect(roundTrip(draft), draft);
      expect(
        draft.copyWith(audioPath: () => null, videoTitle: () => null),
        isNot(draft),
      );
      expect(draft.toJson()['startsMs'], [1000, null]);
    });

    test('a newer format or a malformed draft is refused', () {
      expect(
        () => ContributionDraft.fromJson({
          ...const ContributionDraft().toJson(),
          'format': ContributionDraft.draftFormat + 1,
        }),
        throwsA(isA<LyricsFormatFailure>()),
      );
      expect(
        () => ContributionDraft.fromJson('nope'),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });

    test('an unknown step opens at the lyrics', () {
      final json = const ContributionDraft().toJson()..['step'] = 'later';
      expect(ContributionDraft.fromJson(json).step, DraftStep.lyrics);
    });
  });

  group('toContribution', () {
    test('a new song: a slug from the transliteration, blanks dropped', () {
      final c = const ContributionDraft(song: lyrics).toContribution();
      expect(c.kind, ContributionKind.newSong);
      expect(c.song!.id, 'selam-lezih-bet');
      expect(c.song!.title, 'ሰላም ለዚህ ቤት');
      expect(c.song!.artist, isNull, reason: 'blank');
      expect(c.recording, isNull);
      expect(contributionErrors(c), isEmpty);
    });

    test('the recording belongs to the new song; timings only when synced', () {
      const draft = ContributionDraft(
        song: lyrics,
        recording: local,
        starts: [Duration(seconds: 1), null],
      );
      final half = draft.toContribution();
      expect(half.recording!.songId, 'selam-lezih-bet');
      expect(half.recording!.artist, 'Choir');
      expect(half.timing, isNull, reason: 'one line not tapped');
      expect(draft.synced, isFalse);

      final full = draft.copyWith(
        starts: [const Duration(seconds: 1), const Duration(seconds: 2)],
      );
      expect(full.synced, isTrue);
      expect(full.toContribution().timing!.starts, hasLength(2));
      expect(contributionErrors(full.toContribution()), isEmpty);
    });

    test('a correction keeps its song id and base version', () {
      final c = const ContributionDraft(
        kind: ContributionKind.editLyrics,
        songId: 'selam',
        baseVersion: 3,
        song: lyrics,
      ).toContribution();
      expect(c.songId, 'selam');
      expect(c.song!.id, 'selam');
      expect(c.baseVersion, 3);
    });

    test('a recording and a sync of an existing song', () {
      const timed = [Duration(seconds: 1), Duration(seconds: 2)];
      final recording = const ContributionDraft(
        kind: ContributionKind.recording,
        songId: 'selam',
        song: lyrics,
        recording: local,
        starts: timed,
      ).toContribution();
      expect(recording.recording!.songId, 'selam');
      expect(recording.timing, isNotNull);

      final sync = const ContributionDraft(
        kind: ContributionKind.syncTiming,
        songId: 'selam',
        song: lyrics,
        recording: local,
        starts: timed,
      ).toContribution();
      expect(sync.timing!.recordingId, 'rec-1');
      expect(sync.song, isNull);
    });
  });

  test('lyricsErrors: the song rules, for new songs and corrections', () {
    expect(const ContributionDraft().lyricsErrors, [
      ContributionError.titleRequired,
      ContributionError.noSections,
      ContributionError.playOrderEmpty,
    ]);
    expect(const ContributionDraft(song: lyrics).lyricsErrors, isEmpty);
    expect(
      const ContributionDraft(kind: ContributionKind.syncTiming).lyricsErrors,
      isEmpty,
      reason: "a sync's lyrics are the catalog's",
    );
  });

  test('copyWith can clear the recording and track', () {
    const draft = ContributionDraft(recording: local, trackId: 3);
    final cleared = draft.copyWith(recording: () => null, trackId: () => null);
    expect(cleared.recording, isNull);
    expect(cleared.trackId, isNull);
    expect(draft.copyWith(step: DraftStep.review).recording, local);
  });
}
