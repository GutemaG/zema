import 'dart:convert';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const song = Song(
  id: 'selam',
  title: 'Selam',
  artist: 'Choir',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [
        LyricLine('a', transliteration: 'aa'),
        LyricLine('b'),
      ],
    ),
    LyricSection(id: 'c1', kind: SectionKind.chorus, lines: [LyricLine('c')]),
  ],
  playOrder: ['v1', 'c1', 'c1'],
);

const recording = Recording(
  id: 'r1',
  songId: 'selam',
  source: RecordingSource.localFile,
  artist: 'Choir',
  duration: Duration(minutes: 1),
  fileName: 'Selam.mp3',
);

const timing = SyncTiming(
  recordingId: 'r1',
  starts: [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
  ],
);

/// Through JSON text and back, as the backend stores it.
Contribution roundTrip(Contribution c) => Contribution.fromPayload(
  c.kind,
  jsonDecode(jsonEncode(c.toPayload())),
  songId: c.songId,
  baseVersion: c.baseVersion,
);

void main() {
  group('payloads', () {
    test('a new song: the song, its recording and timing', () {
      const c = Contribution.newSong(
        song,
        recording: recording,
        timing: timing,
      );
      expect(c.toPayload(), {
        'song': song.toJson(),
        'recordings': [recording.toJson()],
        'timings': [timing.toJson()],
      });
      expect(roundTrip(c), c);
      expect(c.songId, isNull);
    });

    test('a new song with lyrics only has no recordings or timings', () {
      expect(const Contribution.newSong(song).toPayload().keys, ['song']);
      expect(roundTrip(const Contribution.newSong(song)).recording, isNull);
    });

    test('a correction: the song, its id and base version', () {
      const c = Contribution.editLyrics(
        songId: 'selam',
        baseVersion: 7,
        song: song,
      );
      expect(c.toPayload().keys, ['song']);
      expect(roundTrip(c), c);
    });

    test('a recording with its timing', () {
      const c = Contribution.recording(
        songId: 'selam',
        recording: recording,
        timing: timing,
      );
      expect(c.toPayload().keys, ['recordings', 'timings']);
      expect(roundTrip(c), c);
    });

    test('a sync: one timing', () {
      const c = Contribution.syncTiming(songId: 'selam', timing: timing);
      expect(c.toPayload(), {
        'timings': [timing.toJson()],
      });
      expect(roundTrip(c), c);
    });

    test('a payload missing what its kind needs is refused', () {
      expect(
        () => Contribution.fromPayload(ContributionKind.newSong, {}),
        throwsA(isA<LyricsFormatFailure>()),
      );
      expect(
        () => Contribution.fromPayload(ContributionKind.syncTiming, {
          'timings': [timing.toJson()],
        }),
        throwsA(isA<LyricsFormatFailure>()),
        reason: 'no song id',
      );
      expect(
        () => Contribution.fromPayload(ContributionKind.recording, {
          'recordings': <Object?>[],
        }, songId: 'selam'),
        throwsA(isA<LyricsFormatFailure>()),
      );
      expect(
        () => Contribution.fromPayload(ContributionKind.newSong, [1]),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });
  });

  group('recordings', () {
    test('keep their YouTube id or file name through JSON', () {
      const youtube = Recording(
        id: 'r2',
        songId: 'selam',
        source: RecordingSource.youtube,
        youtubeId: 'dQw4w9WgXcQ',
      );
      expect(youtube.toJson()['youtubeId'], 'dQw4w9WgXcQ');
      expect(Recording.fromJson(youtube.toJson()), youtube);
      expect(Recording.fromJson(recording.toJson()).fileName, 'Selam.mp3');
      expect(
        Recording.fromJson(recording.toJson()),
        isNot(
          const Recording(
            id: 'r1',
            songId: 'selam',
            source: RecordingSource.localFile,
            artist: 'Choir',
            duration: Duration(minutes: 1),
          ),
        ),
        reason: 'the file name counts for equality',
      );
    });

    test('without them, the JSON has neither key (as before)', () {
      const plain = Recording(
        id: 'r3',
        songId: 'selam',
        source: RecordingSource.bundled,
      );
      expect(plain.toJson().keys, ['id', 'songId', 'source']);
    });
  });

  group('wire names', () {
    test('kinds, statuses and decisions match the backend', () {
      expect(ContributionKind.values.map((k) => k.wire), [
        'new_song',
        'edit_lyrics',
        'recording',
        'sync_timing',
      ]);
      expect(
        ContributionKind.fromWire('sync_timing'),
        ContributionKind.syncTiming,
      );
      expect(
        ContributionStatus.fromWire('changes_requested'),
        ContributionStatus.changesRequested,
      );
      expect(
        () => ContributionStatus.fromWire('published'),
        throwsA(isA<LyricsFormatFailure>()),
      );
      expect(ReviewDecision.values.map((d) => d.wire), [
        'approved',
        'changes_requested',
        'rejected',
      ]);
      expect(ReviewDecision.approve.needsNote, isFalse);
      expect(ReviewDecision.reject.needsNote, isTrue);
    });
  });

  test('a queued correction knows when it was based on an older version', () {
    QueuedContribution queued(int base, int? current) => QueuedContribution(
      id: 'q',
      contribution: Contribution.editLyrics(
        songId: 'selam',
        baseVersion: base,
        song: song,
      ),
      submittedAt: DateTime.utc(2026, 11),
      currentVersion: current,
    );
    expect(queued(3, 5).basedOnOlderVersion, isTrue);
    expect(queued(5, 5).basedOnOlderVersion, isFalse);
    expect(queued(5, null).basedOnOlderVersion, isFalse);
  });
}
