import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

/// Four sung lines: a verse of two, then its chorus twice.
const base = Song(
  id: 'selam',
  title: 'Selam',
  artist: 'Choir',
  sections: [
    LyricSection(
      id: 'v1',
      kind: SectionKind.verse,
      lines: [LyricLine('one'), LyricLine('two')],
    ),
    LyricSection(
      id: 'c1',
      kind: SectionKind.chorus,
      lines: [LyricLine('chorus')],
    ),
  ],
  playOrder: ['v1', 'c1', 'c1'],
);

Song withSections(List<LyricSection> sections, {List<String>? playOrder}) =>
    Song(
      id: base.id,
      title: base.title,
      artist: base.artist,
      sections: sections,
      playOrder: playOrder ?? base.playOrder,
    );

LyricSection verse(List<String> lines) => LyricSection(
  id: 'v1',
  kind: SectionKind.verse,
  lines: [for (final l in lines) LyricLine(l)],
);

LyricSection get chorus => base.sections[1];

Recording recording(String id) =>
    Recording(id: id, songId: 'selam', source: RecordingSource.youtube);

SyncTiming timing(String id, int starts) => SyncTiming(
  recordingId: id,
  starts: [for (var i = 0; i < starts; i++) Duration(seconds: i)],
);

void main() {
  group('changedLines', () {
    test('nothing changed', () {
      expect(changedLines(base, base), isEmpty);
    });

    test('a typo fixed is one changed line', () {
      final edited = withSections([
        verse(['one', 'too']),
        chorus,
      ]);
      expect(changedLines(base, edited), [
        const LineChange(
          sectionId: 'v1',
          kind: LineChangeKind.changed,
          before: LyricLine('two'),
          after: LyricLine('too'),
        ),
      ]);
    });

    test('a line added in the middle, and one removed', () {
      expect(
        changedLines(
          base,
          withSections([
            verse(['one', 'new', 'two']),
            chorus,
          ]),
        ),
        [
          const LineChange(
            sectionId: 'v1',
            kind: LineChangeKind.added,
            after: LyricLine('new'),
          ),
        ],
      );
      expect(
        changedLines(
          base,
          withSections([
            verse(['two']),
            chorus,
          ]),
        ),
        [
          const LineChange(
            sectionId: 'v1',
            kind: LineChangeKind.removed,
            before: LyricLine('one'),
          ),
        ],
      );
    });

    test('a changed transliteration changes the line', () {
      final edited = withSections([
        base.sections[0],
        const LyricSection(
          id: 'c1',
          kind: SectionKind.chorus,
          lines: [LyricLine('chorus', transliteration: 'korus')],
        ),
      ]);
      expect(changedLines(base, edited).single.kind, LineChangeKind.changed);
    });

    test('a new block is added lines; a deleted one removed lines, last', () {
      final edited = withSections(
        [
          const LyricSection(
            id: 'b1',
            kind: SectionKind.bridge,
            lines: [LyricLine('bridge')],
          ),
          chorus,
        ],
        playOrder: ['b1', 'c1'],
      );
      expect(changedLines(base, edited), [
        const LineChange(
          sectionId: 'b1',
          kind: LineChangeKind.added,
          after: LyricLine('bridge'),
        ),
        const LineChange(
          sectionId: 'v1',
          kind: LineChangeKind.removed,
          before: LyricLine('one'),
        ),
        const LineChange(
          sectionId: 'v1',
          kind: LineChangeKind.removed,
          before: LyricLine('two'),
        ),
      ]);
    });

    test('only the play order changed: no line changes', () {
      final edited = withSections(base.sections, playOrder: ['v1', 'c1']);
      expect(changedLines(base, edited), isEmpty);
      expect(songChanged(base, edited), isTrue);
    });
  });

  group('songChanged', () {
    test('spaces around details and a blank one count as unchanged', () {
      final edited = Song(
        id: base.id,
        title: ' Selam ',
        artist: 'Choir',
        album: '  ',
        sections: base.sections,
        playOrder: base.playOrder,
      );
      expect(songChanged(base, edited), isFalse);
      expect(
        songChanged(
          base,
          Song(
            id: base.id,
            title: 'Selam!',
            sections: base.sections,
            playOrder: base.playOrder,
          ),
        ),
        isTrue,
      );
    });

    test('an empty play order is the blocks in order', () {
      const plain = Song(id: 's', title: 't', sections: []);
      expect(
        songChanged(
          withSections(base.sections, playOrder: []),
          withSections(base.sections, playOrder: ['v1', 'c1']),
        ),
        isFalse,
      );
      expect(songChanged(plain, plain), isFalse);
    });
  });

  group('recordingsLosingTimings', () {
    final recordings = [recording('a'), recording('b'), recording('c')];
    // a and b are timed for the four sung lines; c has no timing.
    final timings = [timing('a', 4), timing('b', 4)];

    test('a changed line keeps every timing', () {
      final edited = withSections([
        verse(['one', 'too']),
        chorus,
      ]);
      expect(recordingsLosingTimings(edited, recordings, timings), isEmpty);
    });

    test('a different sung line count drops every timing', () {
      final added = withSections([
        verse(['one', 'two', 'three']),
        chorus,
      ]);
      expect(
        recordingsLosingTimings(added, recordings, timings).map((r) => r.id),
        ['a', 'b'],
      );
      // One chorus less is three sung lines too.
      final shorter = withSections(base.sections, playOrder: ['v1', 'c1']);
      expect(
        recordingsLosingTimings(shorter, recordings, timings),
        hasLength(2),
      );
    });

    test('a timing that already didn\'t fit is dropped too', () {
      expect(
        recordingsLosingTimings(base, recordings, [
          timing('a', 4),
          timing('b', 3),
        ]).map((r) => r.id),
        ['b'],
      );
    });
  });

  group('starting drafts', () {
    test(
      'a correction sends edit_lyrics with the song id and base version',
      () {
        final draft = correctionDraft(base, baseVersion: 7, trackId: 3);
        expect(draft.kind, ContributionKind.editLyrics);
        expect(draft.step, DraftStep.lyrics);
        expect(draft.song, base);
        expect(draft.trackId, 3);
        final contribution = draft.toContribution();
        expect(contribution.kind.wire, 'edit_lyrics');
        expect(contribution.songId, 'selam');
        expect(contribution.baseVersion, 7);
        expect(contribution.song!.id, 'selam');
        expect(contributionErrors(contribution), isEmpty);
      },
    );

    test('a correction of a song without a play order fills it in', () {
      final draft = correctionDraft(
        withSections(base.sections, playOrder: []),
        baseVersion: 1,
      );
      expect(draft.song.playOrder, ['v1', 'c1']);
      expect(draft.lyricsErrors, isEmpty);
    });

    test('a recording for a catalog song starts at S20', () {
      const local = Recording(
        id: 'rec-1',
        songId: '',
        source: RecordingSource.localFile,
        fileName: 'Selam.mp3',
      );
      final draft = recordingDraft(base, recording: local, trackId: 4);
      expect(draft.kind, ContributionKind.recording);
      expect(draft.step, DraftStep.recording);
      final contribution = draft.toContribution();
      expect(contribution.songId, 'selam');
      expect(contribution.recording!.songId, 'selam');
    });

    test('syncing a catalog recording starts at S21', () {
      final draft = syncDraft(base, recording('a'), trackId: 2);
      expect(draft.kind, ContributionKind.syncTiming);
      expect(draft.step, DraftStep.sync);
      expect(draft.trackId, 2);
      final filled = draft.copyWith(
        starts: [for (var i = 0; i < 4; i++) Duration(seconds: i)],
      );
      final contribution = filled.toContribution();
      expect(contribution.songId, 'selam');
      expect(contribution.timing!.recordingId, 'a');
      expect(contribution.timing!.starts, hasLength(4));
    });
  });
}
