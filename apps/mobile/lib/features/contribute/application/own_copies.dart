import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/own_copies_dao.dart';
import '../../account/application/account_providers.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/data/lyrics_links_repository.dart';
import '../data/shared_audio.dart';

/// The user's own copies of contributions waiting for review, last sent
/// first.
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

/// Sends draft [id] ([draft]) for review and returns the contribution's id.
/// What was sent is kept as the user's own copy, and the draft is deleted;
/// Zema's copy of a shared file stays with the own copy until the
/// contribution is reviewed.
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
  final contributionId = await repository.submit(contribution);
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
    await database.draftsDao.remove(id);
  });
  return contributionId;
}

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
        await _links.setManual(copy.trackId!, songId);
      }
      await _copies.remove(copy.contributionId);
      await deleteSharedAudio(copy.audioPath);
      removed.add(copy.contributionId);
    }
    return removed;
  }
}
