import '../failures.dart';
import '../lyrics/lyrics_models.dart';
import '../lyrics/play_order.dart';
import 'contribution.dart';

/// Why the backend refuses a contribution or a review. [code] is the
/// backend's error message; the backend's migrations list the same codes
/// (a test checks they match).
enum ContributionError {
  badPayload('bad_payload'),
  titleRequired('title_required'),
  titleTooLong('title_too_long'),
  fieldTooLong('field_too_long'),
  noSections('no_sections'),
  emptySection('empty_section'),
  badSection('bad_section'),
  tooManyLines('too_many_lines'),
  playOrderEmpty('play_order_empty'),
  playOrderUnknownSection('play_order_unknown_section'),
  badRecording('bad_recording'),
  badVideoId('bad_video_id'),
  timingCount('timing_count'),
  timingOrder('timing_order'),
  timingPastDuration('timing_past_duration'),
  youtubeNotSynced('youtube_not_synced'),
  missingSong('missing_song'),
  missingRecording('missing_recording'),
  missingTiming('missing_timing'),
  songNotAllowed('song_not_allowed'),
  unknownSong('unknown_song'),
  unknownRecording('unknown_recording'),
  badBaseVersion('bad_base_version'),
  notEditable('not_editable'),
  payloadTooLarge('payload_too_large'),
  tooManyOpen('too_many_open'),
  tooManyToday('too_many_today'),
  notSignedIn('not_signed_in'),
  notModerator('not_moderator'),
  ownContribution('own_contribution'),
  alreadyReviewed('already_reviewed'),
  unknownContribution('unknown_contribution'),
  badDecision('bad_decision'),
  noteRequired('note_required'),
  noteTooLong('note_too_long');

  const ContributionError(this.code);

  final String code;

  static final _byCode = {for (final e in values) e.code: e};

  /// The error for backend code [code], or null for one this app doesn't
  /// know.
  static ContributionError? fromCode(String code) => _byCode[code];
}

extension ContributionFailureError on ContributionFailure {
  /// The refusal as a [ContributionError]; null for a code this app doesn't
  /// know.
  ContributionError? get error => ContributionError.fromCode(code);
}

/// Limits the backend enforces too.
const maxTitleLength = 200;
const maxFieldLength = 200;
const maxLineLength = 500;
const maxWrittenLines = 300;
const maxFileNameLength = 255;
const maxSlugLength = 120;
const maxNoteLength = 1000;

final _slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Whether [id] can be a song or recording id on the backend.
bool isValidSlug(String id) => id.length <= maxSlugLength && _slug.hasMatch(id);

/// Whether [id] looks like a YouTube video id.
bool isValidVideoId(String id) => _videoId.hasMatch(id);

/// How many lines [song] sings: one start each in a timing.
int sungLineCount(Song song) => expandPlayOrder(song).occurrences.length;

/// The rules [song] breaks, each once, in the backend's order.
List<ContributionError> songErrors(Song song) {
  final errors = <ContributionError>{};
  final title = song.title.trim();
  if (title.isEmpty) errors.add(ContributionError.titleRequired);
  if (title.length > maxTitleLength) errors.add(ContributionError.titleTooLong);
  if ([
    song.transliteration,
    song.artist,
    song.album,
  ].any((f) => f != null && f.length > maxFieldLength)) {
    errors.add(ContributionError.fieldTooLong);
  }
  if (song.sections.isEmpty) errors.add(ContributionError.noSections);
  final ids = <String>{};
  var written = 0;
  for (final section in song.sections) {
    if (section.id.isEmpty ||
        section.id.length > maxSlugLength ||
        !ids.add(section.id)) {
      errors.add(ContributionError.badSection);
    }
    if (section.lines.isEmpty) errors.add(ContributionError.emptySection);
    for (final line in section.lines) {
      if (line.text.trim().isEmpty) errors.add(ContributionError.emptySection);
      if (line.text.length > maxLineLength ||
          (line.transliteration?.length ?? 0) > maxLineLength) {
        errors.add(ContributionError.fieldTooLong);
      }
      written++;
    }
  }
  if (written > maxWrittenLines) errors.add(ContributionError.tooManyLines);
  if (song.playOrder.isEmpty) errors.add(ContributionError.playOrderEmpty);
  if (song.playOrder.any((id) => !ids.contains(id))) {
    errors.add(ContributionError.playOrderUnknownSection);
  }
  return errors.toList();
}

/// The rules [recording] breaks as a recording of song [songId].
List<ContributionError> recordingErrors(
  Recording recording, {
  required String songId,
}) {
  final errors = <ContributionError>{};
  if (!isValidSlug(recording.id) ||
      recording.songId != songId ||
      recording.source == RecordingSource.bundled ||
      (recording.artist?.length ?? 0) > maxFieldLength ||
      (recording.duration != null && recording.duration! <= Duration.zero)) {
    errors.add(ContributionError.badRecording);
  }
  if (recording.source == RecordingSource.youtube) {
    if (!isValidVideoId(recording.youtubeId ?? '')) {
      errors.add(ContributionError.badVideoId);
    }
  } else {
    final name = recording.fileName ?? '';
    if (name.trim().isEmpty || name.length > maxFileNameLength) {
      errors.add(ContributionError.badRecording);
    }
  }
  return errors.toList();
}

/// The rules [timing] breaks as the timing of [recording] for a song
/// singing [sungLines] lines.
List<ContributionError> timingErrors(
  SyncTiming timing, {
  required Recording recording,
  required int sungLines,
}) {
  if (timing.recordingId != recording.id) {
    return [ContributionError.unknownRecording];
  }
  if (recording.source == RecordingSource.youtube) {
    return [ContributionError.youtubeNotSynced];
  }
  final errors = <ContributionError>{};
  if (timing.starts.length != sungLines) {
    errors.add(ContributionError.timingCount);
  }
  Duration? previous;
  for (final start in timing.starts) {
    if (start.isNegative || (previous != null && start <= previous)) {
      errors.add(ContributionError.timingOrder);
    }
    if (recording.duration case final duration? when start >= duration) {
      errors.add(ContributionError.timingPastDuration);
    }
    previous = start;
  }
  return errors.toList();
}

/// The rules [contribution] breaks, in the backend's order; empty when the
/// backend would accept it (apart from what only it knows, such as limits).
///
/// For a recording or sync of an existing song, pass the song as it is now
/// ([currentSong]) to count its sung lines, and for a sync the recording
/// it times ([existingRecording]); without them those checks are left to
/// the backend.
List<ContributionError> contributionErrors(
  Contribution contribution, {
  Song? currentSong,
  Recording? existingRecording,
}) {
  final song = contribution.song;
  final recording = contribution.recording;
  final timing = contribution.timing;
  switch (contribution.kind) {
    case ContributionKind.newSong:
      final errors = songErrors(song!);
      if (timing != null && recording == null) {
        return [...errors, ContributionError.missingRecording];
      }
      if (recording != null) {
        errors.addAll(recordingErrors(recording, songId: song.id));
        if (timing != null) {
          errors.addAll(
            timingErrors(
              timing,
              recording: recording,
              sungLines: sungLineCount(song),
            ),
          );
        }
      }
      return {...errors}.toList();
    case ContributionKind.editLyrics:
      return [
        if (contribution.baseVersion! < 1) ContributionError.badBaseVersion,
        if (song!.id != contribution.songId) ContributionError.badPayload,
        ...songErrors(song),
      ];
    case ContributionKind.recording:
      final errors = recordingErrors(recording!, songId: contribution.songId!);
      if (timing != null && currentSong != null) {
        errors.addAll(
          timingErrors(
            timing,
            recording: recording,
            sungLines: sungLineCount(currentSong),
          ),
        );
      }
      return {...errors}.toList();
    case ContributionKind.syncTiming:
      if (existingRecording == null || currentSong == null) return const [];
      if (existingRecording.songId != contribution.songId) {
        return [ContributionError.unknownRecording];
      }
      return timingErrors(
        timing!,
        recording: existingRecording,
        sungLines: sungLineCount(currentSong),
      );
  }
}
