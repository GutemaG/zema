import '../failures.dart';
import '../lyrics/lyrics_models.dart';
import 'contribution.dart';
import 'contribution_rules.dart';
import 'song_slug.dart';

/// The four steps of contributing, in order.
enum DraftStep { lyrics, recording, sync, review }

/// One contribution in progress, saved on the phone as the user works.
///
/// [song] is the lyrics so far; its id is left empty for a new song until
/// [toContribution] proposes one from the title. [starts] has one start per
/// sung line once syncing begins, null for lines not tapped yet.
class ContributionDraft {
  const ContributionDraft({
    this.kind = ContributionKind.newSong,
    this.songId,
    this.baseVersion,
    this.song = const Song(id: '', title: '', sections: []),
    this.recording,
    this.starts = const [],
    this.trackId,
    this.audioPath,
    this.videoTitle,
    this.step = DraftStep.lyrics,
  });

  /// Reads [json] (see [toJson]). Throws [LyricsFormatFailure] when it is
  /// malformed or from a newer app.
  factory ContributionDraft.fromJson(Object? json) {
    if (json is! Map) {
      throw const LyricsFormatFailure('A draft must be a JSON object');
    }
    final format = json['format'];
    if (format is! int || format > draftFormat) {
      throw LyricsFormatFailure('Unknown draft format $format');
    }
    final starts = json['startsMs'];
    return ContributionDraft(
      kind: ContributionKind.fromWire(json['kind'] as String? ?? ''),
      songId: json['songId'] as String?,
      baseVersion: json['baseVersion'] as int?,
      song: Song.fromJson(json['song']),
      recording: json['recording'] == null
          ? null
          : Recording.fromJson(json['recording']),
      starts: [
        if (starts is List)
          for (final ms in starts)
            ms is int ? Duration(milliseconds: ms) : null,
      ],
      trackId: json['trackId'] as int?,
      audioPath: json['audioPath'] as String?,
      videoTitle: json['videoTitle'] as String?,
      step: DraftStep.values.asNameMap()[json['step']] ?? DraftStep.lyrics,
    );
  }

  /// Version of [toJson]'s layout.
  static const draftFormat = 1;

  final ContributionKind kind;

  /// The catalog song it changes; null for a new song.
  final String? songId;

  /// The song version a correction started from.
  final int? baseVersion;
  final Song song;
  final Recording? recording;
  final List<Duration?> starts;

  /// The local track the user started from, if any.
  final int? trackId;

  /// Zema's own copy of an audio file shared to it (Telegram), which the
  /// sync editor plays; deleted with the draft.
  final String? audioPath;

  /// The YouTube video's title, shown on S20; not sent.
  final String? videoTitle;
  final DraftStep step;

  /// The title as shown in lists; empty until typed.
  String get title => song.title.trim();

  /// Whether every sung line has a start.
  bool get synced =>
      starts.isNotEmpty &&
      starts.length == sungLineCount(song) &&
      starts.every((s) => s != null);

  /// What would be sent: a new song gets an id proposed from its title, and
  /// its recording that song id. Timings are included only when [synced].
  Contribution toContribution() {
    final id = switch (kind) {
      ContributionKind.newSong => proposeSongSlug(
        song.title,
        transliteration: song.transliteration,
      ),
      _ => songId ?? '',
    };
    final lyrics = Song(
      id: id,
      title: song.title.trim(),
      transliteration: _blankToNull(song.transliteration),
      artist: _blankToNull(song.artist),
      album: _blankToNull(song.album),
      sections: song.sections,
      playOrder: song.playOrder,
    );
    final recording = switch (this.recording) {
      null => null,
      final r => Recording(
        id: r.id,
        songId: id,
        source: r.source,
        artist: _blankToNull(r.artist),
        duration: r.duration,
        youtubeId: r.youtubeId,
        fileName: r.fileName,
      ),
    };
    final timing = recording == null || !synced
        ? null
        : SyncTiming(
            recordingId: recording.id,
            starts: [for (final s in starts) s!],
          );
    return switch (kind) {
      ContributionKind.newSong => Contribution.newSong(
        lyrics,
        recording: recording,
        timing: timing,
      ),
      ContributionKind.editLyrics => Contribution.editLyrics(
        songId: id,
        baseVersion: baseVersion ?? 0,
        song: lyrics,
      ),
      ContributionKind.recording => Contribution.recording(
        songId: id,
        recording: recording!,
        timing: timing,
      ),
      ContributionKind.syncTiming => Contribution.syncTiming(
        songId: id,
        timing:
            timing ??
            SyncTiming(recordingId: recording?.id ?? '', starts: const []),
      ),
    };
  }

  /// The rules the lyrics break (for a new song or a correction); empty for
  /// the other kinds, whose song is the catalog's.
  List<ContributionError> get lyricsErrors => switch (kind) {
    ContributionKind.newSong ||
    ContributionKind.editLyrics => songErrors(toContribution().song!),
    _ => const [],
  };

  ContributionDraft copyWith({
    Song? song,
    Recording? Function()? recording,
    List<Duration?>? starts,
    int? Function()? trackId,
    String? Function()? audioPath,
    String? Function()? videoTitle,
    DraftStep? step,
  }) => ContributionDraft(
    kind: kind,
    songId: songId,
    baseVersion: baseVersion,
    song: song ?? this.song,
    recording: recording == null ? this.recording : recording(),
    starts: starts ?? this.starts,
    trackId: trackId == null ? this.trackId : trackId(),
    audioPath: audioPath == null ? this.audioPath : audioPath(),
    videoTitle: videoTitle == null ? this.videoTitle : videoTitle(),
    step: step ?? this.step,
  );

  Map<String, Object?> toJson() => {
    'format': draftFormat,
    'kind': kind.wire,
    'songId': ?songId,
    'baseVersion': ?baseVersion,
    'song': song.toJson(),
    if (recording case final r?) 'recording': r.toJson(),
    if (starts.isNotEmpty)
      'startsMs': [for (final s in starts) s?.inMilliseconds],
    'trackId': ?trackId,
    'audioPath': ?audioPath,
    'videoTitle': ?videoTitle,
    'step': step.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ContributionDraft &&
      other.kind == kind &&
      other.songId == songId &&
      other.baseVersion == baseVersion &&
      other.song == song &&
      other.recording == recording &&
      _sameStarts(other.starts, starts) &&
      other.trackId == trackId &&
      other.audioPath == audioPath &&
      other.videoTitle == videoTitle &&
      other.step == step;

  @override
  int get hashCode => Object.hash(
    kind,
    songId,
    baseVersion,
    song,
    recording,
    Object.hashAll(starts),
    trackId,
    audioPath,
    videoTitle,
    step,
  );
}

String? _blankToNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _sameStarts(List<Duration?> a, List<Duration?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
