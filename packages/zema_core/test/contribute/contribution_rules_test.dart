import 'dart:io';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

import 'contribution_test.dart' show recording, song, timing;

typedef E = ContributionError;

Song withSections(List<LyricSection> sections, {List<String>? playOrder}) =>
    Song(
      id: song.id,
      title: song.title,
      sections: sections,
      playOrder: playOrder ?? [for (final s in sections) s.id],
    );

Song copy({
  String? id,
  String? title,
  String? artist,
  List<String>? playOrder,
}) => Song(
  id: id ?? song.id,
  title: title ?? song.title,
  artist: artist ?? song.artist,
  sections: song.sections,
  playOrder: playOrder ?? song.playOrder,
);

Recording rec({
  String id = 'r1',
  String songId = 'selam',
  RecordingSource source = RecordingSource.localFile,
  Duration? duration = const Duration(minutes: 1),
  String? fileName = 'Selam.mp3',
  String? youtubeId,
  String? artist,
}) => Recording(
  id: id,
  songId: songId,
  source: source,
  duration: duration,
  fileName: fileName,
  youtubeId: youtubeId,
  artist: artist,
);

SyncTiming starts(List<int> seconds, {String recordingId = 'r1'}) => SyncTiming(
  recordingId: recordingId,
  starts: [for (final s in seconds) Duration(seconds: s)],
);

List<E> newSong(Song s, {Recording? recording, SyncTiming? timing}) =>
    contributionErrors(
      Contribution.newSong(s, recording: recording, timing: timing),
    );

void main() {
  test('a song sings its lines once per play-order entry', () {
    expect(sungLineCount(song), 4);
    expect(sungLineCount(copy(playOrder: [])), 3, reason: 'each section once');
  });

  group('valid', () {
    test('every kind passes', () {
      expect(newSong(song), isEmpty);
      expect(newSong(song, recording: recording, timing: timing), isEmpty);
      expect(
        newSong(
          song,
          recording: rec(
            source: RecordingSource.youtube,
            fileName: null,
            youtubeId: 'dQw4w9WgXcQ',
          ),
        ),
        isEmpty,
      );
      expect(
        contributionErrors(
          const Contribution.editLyrics(
            songId: 'selam',
            baseVersion: 1,
            song: song,
          ),
        ),
        isEmpty,
      );
      expect(
        contributionErrors(
          const Contribution.recording(
            songId: 'selam',
            recording: recording,
            timing: timing,
          ),
          currentSong: song,
        ),
        isEmpty,
      );
      expect(
        contributionErrors(
          const Contribution.syncTiming(songId: 'selam', timing: timing),
          currentSong: song,
          existingRecording: recording,
        ),
        isEmpty,
      );
    });
  });

  group('the song', () {
    test('title', () {
      expect(newSong(copy(title: '   ')), [E.titleRequired]);
      expect(newSong(copy(title: 't' * 200)), isEmpty);
      expect(
        newSong(copy(title: ' ${'t' * 200} ')),
        isEmpty,
        reason: 'trimmed',
      );
      expect(newSong(copy(title: 't' * 201)), [E.titleTooLong]);
    });

    test('other fields and lines have limits', () {
      expect(newSong(copy(artist: 'a' * 201)), [E.fieldTooLong]);
      expect(
        newSong(
          withSections([
            LyricSection(
              id: 'v',
              kind: SectionKind.verse,
              lines: [LyricLine('l' * 501)],
            ),
          ]),
        ),
        [E.fieldTooLong],
      );
    });

    test('sections', () {
      expect(newSong(withSections([])), [E.noSections, E.playOrderEmpty]);
      expect(
        newSong(
          withSections([
            const LyricSection(id: 'v', kind: SectionKind.verse, lines: []),
          ]),
        ),
        [E.emptySection],
      );
      expect(
        newSong(
          withSections([
            const LyricSection(
              id: 'v',
              kind: SectionKind.verse,
              lines: [LyricLine('a'), LyricLine('  ')],
            ),
          ]),
        ),
        [E.emptySection],
      );
      expect(
        newSong(
          withSections([
            const LyricSection(
              id: 'v',
              kind: SectionKind.verse,
              lines: [LyricLine('a')],
            ),
            const LyricSection(
              id: 'v',
              kind: SectionKind.chorus,
              lines: [LyricLine('b')],
            ),
          ]),
        ),
        [E.badSection],
      );
    });

    test('at most 300 written lines', () {
      LyricSection lines(int n) => LyricSection(
        id: 'v',
        kind: SectionKind.verse,
        lines: [for (var i = 0; i < n; i++) LyricLine('l$i')],
      );
      expect(newSong(withSections([lines(300)])), isEmpty);
      expect(newSong(withSections([lines(301)])), [E.tooManyLines]);
    });

    test('play order', () {
      expect(newSong(copy(playOrder: [])), [E.playOrderEmpty]);
      expect(newSong(copy(playOrder: ['v1', 'x'])), [
        E.playOrderUnknownSection,
      ]);
    });

    test('several broken rules are each listed once, in order', () {
      expect(newSong(copy(title: '', playOrder: ['x', 'y'])), [
        E.titleRequired,
        E.playOrderUnknownSection,
      ]);
    });
  });

  group('the recording', () {
    test('bad recordings', () {
      for (final bad in [
        rec(source: RecordingSource.bundled),
        rec(fileName: null),
        rec(fileName: '  '),
        rec(fileName: 'f' * 256),
        rec(duration: Duration.zero),
        rec(songId: 'other'),
        rec(id: 'Not A Slug'),
        rec(artist: 'a' * 201),
      ]) {
        expect(newSong(song, recording: bad), [E.badRecording], reason: '$bad');
      }
      expect(newSong(song, recording: rec(duration: null)), isEmpty);
    });

    test('a YouTube recording needs an 11-character video id', () {
      Recording yt(String? id) =>
          rec(source: RecordingSource.youtube, fileName: null, youtubeId: id);
      expect(newSong(song, recording: yt('short')), [E.badVideoId]);
      expect(newSong(song, recording: yt(null)), [E.badVideoId]);
    });
  });

  group('timings', () {
    test('one start per sung line', () {
      expect(newSong(song, recording: recording, timing: starts([1, 2, 3])), [
        E.timingCount,
      ]);
    });

    test('strictly increasing and not negative', () {
      expect(
        newSong(song, recording: recording, timing: starts([1, 2, 2, 4])),
        [E.timingOrder],
      );
      expect(
        newSong(song, recording: recording, timing: starts([-1, 2, 3, 4])),
        [E.timingOrder],
      );
    });

    test('within the recording when its length is known', () {
      expect(
        newSong(song, recording: recording, timing: starts([1, 2, 3, 60])),
        [E.timingPastDuration],
      );
      expect(
        newSong(
          song,
          recording: rec(duration: null),
          timing: starts([1, 2, 3, 90]),
        ),
        isEmpty,
      );
    });

    test('YouTube recordings are not synced', () {
      expect(
        newSong(
          song,
          recording: rec(
            source: RecordingSource.youtube,
            fileName: null,
            youtubeId: 'dQw4w9WgXcQ',
          ),
          timing: timing,
        ),
        [E.youtubeNotSynced],
      );
    });

    test('a timing belongs to its recording', () {
      expect(
        newSong(
          song,
          recording: recording,
          timing: starts([1, 2, 3, 4], recordingId: 'r9'),
        ),
        [E.unknownRecording],
      );
    });
  });

  group('kinds', () {
    test('a new song with a timing but no recording', () {
      expect(newSong(song, timing: timing), [E.missingRecording]);
    });

    test('a correction needs its own song id and a base version', () {
      expect(
        contributionErrors(
          const Contribution.editLyrics(
            songId: 'other',
            baseVersion: 1,
            song: song,
          ),
        ),
        [E.badPayload],
      );
      expect(
        contributionErrors(
          const Contribution.editLyrics(
            songId: 'selam',
            baseVersion: 0,
            song: song,
          ),
        ),
        [E.badBaseVersion],
      );
    });

    test('a recording or sync counts lines of the song as it is now', () {
      final longer = copy(playOrder: ['v1', 'c1', 'c1', 'c1']);
      expect(
        contributionErrors(
          const Contribution.recording(
            songId: 'selam',
            recording: recording,
            timing: timing,
          ),
          currentSong: longer,
        ),
        [E.timingCount],
      );
      expect(
        contributionErrors(
          const Contribution.syncTiming(songId: 'selam', timing: timing),
          currentSong: longer,
          existingRecording: recording,
        ),
        [E.timingCount],
      );
    });

    test('without the current song, those checks are left to the backend', () {
      expect(
        contributionErrors(
          Contribution.syncTiming(songId: 'selam', timing: starts([1])),
        ),
        isEmpty,
      );
    });

    test('a sync for a recording of another song', () {
      expect(
        contributionErrors(
          const Contribution.syncTiming(songId: 'selam', timing: timing),
          currentSong: song,
          existingRecording: rec(songId: 'other'),
        ),
        [E.unknownRecording],
      );
    });
  });

  group('codes', () {
    test('a failure reads its code', () {
      expect(
        const ContributionFailure('x', code: 'too_many_open').error,
        E.tooManyOpen,
      );
      expect(const ContributionFailure('x', code: 'new_rule').error, isNull);
    });

    test('are the backend\'s codes, no more and no fewer', () {
      final migrations = Directory('../../backend/supabase/migrations');
      final header = [
        for (final name in [
          '20261102000100_submit_contributions.sql',
          '20261102010000_review_contributions.sql',
        ])
          File('${migrations.path}/$name')
              .readAsLinesSync()
              .takeWhile((l) => l.startsWith('--'))
              .skipWhile((l) => !l.startsWith('-- Error'))
              // The codes follow that line.
              .skip(1)
              .join(' '),
      ].join(' ');
      // The codes are listed after their errcode: "22023  bad_payload, ...".
      final listed = RegExp(r'\b[a-z]+(?:_[a-z]+)+\b')
          .allMatches(header)
          .map((m) => m.group(0)!)
          .where((w) => !const {'pending', 'changes_requested'}.contains(w))
          .toSet();
      expect(listed, {for (final e in ContributionError.values) e.code});
    });

    test('the limits are the backend\'s', () {
      final header = File(
        '../../backend/supabase/migrations/'
        '20261102000100_submit_contributions.sql',
      ).readAsStringSync();
      expect(
        header,
        contains('too_many_open ($maxOpenContributions pending or'),
      );
      expect(
        header,
        contains('too_many_today ($maxContributionsPerDay in 24 hours)'),
      );
    });
  });

  test('slugs and video ids', () {
    expect(isValidSlug('selam-lezih-bet'), isTrue);
    expect(isValidSlug('Selam'), isFalse);
    expect(isValidSlug('a' * 121), isFalse);
    expect(isValidVideoId('dQw4w9WgXcQ'), isTrue);
    expect(isValidVideoId('dQw4w9WgXc'), isFalse);
  });
}
