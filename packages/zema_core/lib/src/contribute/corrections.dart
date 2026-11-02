import '../lyrics/lyrics_models.dart';
import 'contribution.dart';
import 'contribution_draft.dart';
import 'contribution_rules.dart';

/// How a written line differs between a song and its correction.
enum LineChangeKind { added, removed, changed }

/// One line a correction adds, removes or changes, in block [sectionId].
/// [before] is the catalog's line (null when added), [after] the corrected
/// one (null when removed).
class LineChange {
  const LineChange({
    required this.sectionId,
    required this.kind,
    this.before,
    this.after,
  });

  final String sectionId;
  final LineChangeKind kind;
  final LyricLine? before;
  final LyricLine? after;

  @override
  bool operator ==(Object other) =>
      other is LineChange &&
      other.sectionId == sectionId &&
      other.kind == kind &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(sectionId, kind, before, after);

  @override
  String toString() =>
      'LineChange($sectionId ${kind.name}: ${before?.text} → ${after?.text})';
}

/// The written lines [edited] adds, removes or changes compared with
/// [base], block by block (blocks match by id): the corrected blocks in
/// their order, then blocks that were deleted. Each line counts once,
/// however often its block is sung. Within a block, a removed line followed
/// by an added one is a change. A changed transliteration changes the line.
List<LineChange> changedLines(Song base, Song edited) {
  final before = {for (final s in base.sections) s.id: s};
  final kept = {for (final s in edited.sections) s.id};
  return [
    for (final section in edited.sections)
      ..._diff(
        section.id,
        before[section.id]?.lines ?? const [],
        section.lines,
      ),
    for (final section in base.sections)
      if (!kept.contains(section.id))
        ..._diff(section.id, section.lines, const []),
  ];
}

/// Lines [a] → [b] through their longest common subsequence.
List<LineChange> _diff(String sectionId, List<LyricLine> a, List<LyricLine> b) {
  // common[i][j]: the longest common subsequence of a[i..] and b[j..].
  final common = List.generate(
    a.length + 1,
    (_) => List.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      common[i][j] = a[i] == b[j]
          ? common[i + 1][j + 1] + 1
          : (common[i + 1][j] >= common[i][j + 1]
                ? common[i + 1][j]
                : common[i][j + 1]);
    }
  }
  final changes = <LineChange>[];
  final removed = <LyricLine>[];
  final added = <LyricLine>[];
  void flush() {
    final pairs = removed.length < added.length ? removed.length : added.length;
    for (var k = 0; k < pairs; k++) {
      changes.add(
        LineChange(
          sectionId: sectionId,
          kind: LineChangeKind.changed,
          before: removed[k],
          after: added[k],
        ),
      );
    }
    for (final line in removed.skip(pairs)) {
      changes.add(
        LineChange(
          sectionId: sectionId,
          kind: LineChangeKind.removed,
          before: line,
        ),
      );
    }
    for (final line in added.skip(pairs)) {
      changes.add(
        LineChange(
          sectionId: sectionId,
          kind: LineChangeKind.added,
          after: line,
        ),
      );
    }
    removed.clear();
    added.clear();
  }

  var i = 0;
  var j = 0;
  while (i < a.length || j < b.length) {
    if (i < a.length && j < b.length && a[i] == b[j]) {
      flush();
      i++;
      j++;
    } else if (j >= b.length ||
        (i < a.length && common[i + 1][j] >= common[i][j + 1])) {
      removed.add(a[i++]);
    } else {
      added.add(b[j++]);
    }
  }
  flush();
  return changes;
}

/// Whether [edited] differs from [base] in what a correction sends: the
/// details (ignoring spaces around them, a blank one counting as none), the
/// blocks or the play order.
bool songChanged(Song base, Song edited) {
  String? clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> order(Song song) => song.playOrder.isEmpty
      ? [for (final s in song.sections) s.id]
      : song.playOrder;
  bool sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  return clean(base.title) != clean(edited.title) ||
      clean(base.transliteration) != clean(edited.transliteration) ||
      clean(base.artist) != clean(edited.artist) ||
      clean(base.album) != clean(edited.album) ||
      !sameList(base.sections, edited.sections) ||
      !sameList(order(base), order(edited));
}

/// The [recordings] whose timing the catalog drops when the correction
/// [edited] is approved: as the backend's `publish_contribution` does, every
/// timing in [timings] whose number of starts isn't [edited]'s sung line
/// count. Recordings without a timing never lose one.
List<Recording> recordingsLosingTimings(
  Song edited,
  List<Recording> recordings,
  List<SyncTiming> timings,
) {
  final sung = sungLineCount(edited);
  final dropped = {
    for (final t in timings)
      if (t.starts.length != sung) t.recordingId,
  };
  return [
    for (final r in recordings)
      if (dropped.contains(r.id)) r,
  ];
}

/// A draft correcting the catalog's [song], at [baseVersion], at S19 with
/// the song filled in. A song without a play order gets its blocks in
/// order, which is how it is sung.
ContributionDraft correctionDraft(
  Song song, {
  required int baseVersion,
  int? trackId,
  String? audioPath,
}) => ContributionDraft(
  kind: ContributionKind.editLyrics,
  songId: song.id,
  baseVersion: baseVersion,
  song: Song(
    id: song.id,
    title: song.title,
    transliteration: song.transliteration,
    artist: song.artist,
    album: song.album,
    sections: song.sections,
    playOrder: song.playOrder.isEmpty
        ? [for (final s in song.sections) s.id]
        : song.playOrder,
  ),
  trackId: trackId,
  audioPath: audioPath,
);

/// A draft adding a recording of the catalog's [song], at S20. [recording],
/// [trackId] and [audioPath] carry over what the user already chose.
ContributionDraft recordingDraft(
  Song song, {
  Recording? recording,
  int? trackId,
  String? audioPath,
  String? videoTitle,
}) => ContributionDraft(
  kind: ContributionKind.recording,
  songId: song.id,
  song: song,
  recording: recording,
  trackId: trackId,
  audioPath: audioPath,
  videoTitle: videoTitle,
  step: DraftStep.recording,
);

/// A draft timing the catalog's [recording] of [song], at S21, playing the
/// library track [trackId].
ContributionDraft syncDraft(Song song, Recording recording, {int? trackId}) =>
    ContributionDraft(
      kind: ContributionKind.syncTiming,
      songId: song.id,
      song: song,
      recording: recording,
      trackId: trackId,
      step: DraftStep.sync,
    );
