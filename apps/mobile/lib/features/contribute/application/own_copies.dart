import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/own_copies_dao.dart';
import '../../account/application/account_providers.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/data/lyrics_links_repository.dart';
import '../data/shared_audio.dart';

/// The user's own copies of contributions waiting for review, and lyrics
/// saved on this phone only, last sent or saved first.
final ownCopiesProvider = StreamProvider<List<OwnCopy>>(
  (ref) => ref.watch(databaseProvider).ownCopiesDao.watchAll(),
);

/// The latest own copy made for track [trackId], or null.
final trackOwnCopyProvider = Provider.family<AsyncValue<OwnCopy?>, int>(
  (ref, trackId) => ref
      .watch(ownCopiesProvider)
      .whenData(
        (copies) => copies.where((c) => c.trackId == trackId).firstOrNull,
      ),
);

/// The rules [draft] breaks, checked again before it is sent: its lyrics,
/// then the whole contribution.
List<ContributionError> draftErrors(ContributionDraft draft) => {
  ...draft.lyricsErrors,
  ...contributionErrors(draft.toContribution()),
}.toList();

/// Saves draft [id] ([draft]) on this phone only, for its track: no account
/// is needed, and the track shows the lyrics (marked as on this phone) until
/// they are saved again or sent. The draft stays, to edit or send later.
///
/// Throws a [ContributionFailure] when the lyrics break a rule, or the draft
/// has no track.
Future<void> saveDraftLocally(
  WidgetRef ref,
  int id,
  ContributionDraft draft,
) async {
  final trackId =
      draft.trackId ??
      (throw ContributionFailure(
        'Draft $id: no track',
        code: ContributionError.missingSong.code,
      ));
  if (draft.lyricsErrors case [final error, ...]) {
    throw ContributionFailure('Draft $id: ${error.code}', code: error.code);
  }
  final recording = draft.recording;
  await ref
      .read(databaseProvider)
      .ownCopiesDao
      .add(
        OwnCopy(
          contributionId: localCopyId(id),
          kind: draft.kind,
          song: draft.song,
          recording: recording,
          timing: recording == null || !draft.synced
              ? null
              : SyncTiming(
                  recordingId: recording.id,
                  starts: [for (final s in draft.starts) s!],
                ),
          trackId: trackId,
          audioPath: draft.audioPath,
          submittedAt: clock.now(),
        ),
      );
}

/// Sends draft [id] ([draft]) for review, or again when it resubmits one
/// sent back for changes, and returns the contribution's id.
/// What was sent is kept as the user's own copy, and the draft is deleted,
/// with the lyrics saved from it on this phone only; Zema's copy of a
/// shared file stays with the own copy until the contribution is reviewed.
///
/// Throws a [ContributionFailure] for a rule the draft breaks (checked
/// here first), an [AuthFailure] without a backend, and the repository's
/// failures. The draft is kept then.
Future<String> submitDraft(
  WidgetRef ref,
  int id,
  ContributionDraft draft,
) async {
  final repository =
      ref.read(contributionRepositoryProvider) ??
      (throw const AuthFailure('No backend'));
  if (draftErrors(draft) case [final error, ...]) {
    throw ContributionFailure('Draft $id: ${error.code}', code: error.code);
  }
  final contribution = draft.toContribution();
  final resubmitId = draft.resubmitId;
  final String contributionId;
  if (resubmitId == null) {
    contributionId = await repository.submit(contribution);
  } else {
    await repository.resubmit(resubmitId, contribution);
    contributionId = resubmitId;
  }
  final database = ref.read(databaseProvider);
  await database.transaction(() async {
    await database.ownCopiesDao.add(
      OwnCopy(
        contributionId: contributionId,
        kind: contribution.kind,
        song:
            contribution.song ??
            Song(
              id: contribution.songId ?? '',
              title: draft.song.title,
              transliteration: draft.song.transliteration,
              artist: draft.song.artist,
              album: draft.song.album,
              sections: draft.song.sections,
              playOrder: draft.song.playOrder,
            ),
        recording: contribution.recording ?? draft.recording,
        timing: contribution.timing,
        trackId: draft.trackId,
        audioPath: draft.audioPath,
        submittedAt: clock.now(),
      ),
    );
    await database.ownCopiesDao.remove(localCopyId(id));
    await database.draftsDao.remove(id);
  });
  return contributionId;
}

final _log = Logger('OwnCopies');

/// Applies reviews to the own copies (see [OwnCopyReconciler]).
final ownCopyReconcilerProvider = Provider<OwnCopyReconciler>(
  (ref) => OwnCopyReconciler(
    ref.watch(databaseProvider).ownCopiesDao,
    ref.watch(lyricsLinksRepositoryProvider),
  ),
);

/// Replaces own copies once their contributions are reviewed. Call
/// [reconcile] whenever the user's contributions are fetched.
class OwnCopyReconciler {
  const OwnCopyReconciler(this._copies, this._links);

  final OwnCopiesDao _copies;
  final LyricsLinksRepository _links;

  /// Applies the reviews in [mine] (the user's contributions):
  ///
  /// - approved: the copy's track is linked to the catalog song it became
  ///   (or changed), and the copy removed, so the track shows the catalog's
  ///   version
  /// - rejected: the copy is removed, so the track goes back to what it had
  ///
  /// Either way Zema's copy of a shared file goes too. Copies still
  /// pending, sent back for changes, or not in [mine] stay. Returns the ids
  /// of the copies removed.
  Future<List<String>> reconcile(List<SubmittedContribution> mine) async {
    final reviewed = {
      for (final c in mine)
        if (c.status == ContributionStatus.approved ||
            c.status == ContributionStatus.rejected)
          c.id: c,
    };
    final removed = <String>[];
    for (final copy in await _copies.all()) {
      final review = reviewed[copy.contributionId];
      if (review == null) continue;
      final songId = review.songId ?? review.contribution.song?.id;
      if (review.status == ContributionStatus.approved &&
          copy.trackId != null &&
          songId != null) {
        try {
          await _links.setManual(copy.trackId!, songId);
        } on DatabaseFailure catch (e) {
          // The track is gone from the phone; the copy goes all the same.
          _log.info('Linking ${copy.trackId} to $songId failed', e);
        }
      }
      await _copies.remove(copy.contributionId);
      await deleteSharedAudio(copy.audioPath);
      removed.add(copy.contributionId);
    }
    return removed;
  }
}
