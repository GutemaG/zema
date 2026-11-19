/// The site's text. English only: the site is for moderators.
abstract final class Strings {
  static const appName = 'Zema Admin';
  static const signIn = 'Sign in with Google';
  static const signInHint = 'For Zema moderators.';
  static const signOut = 'Sign out';
  static const notModerator = 'Not a moderator';
  static const notModeratorHint =
      'This account can’t moderate. Ask the owner to grant the moderator role.';
  static const notConfigured =
      'No backend set. Build with --dart-define-from-file (see docs/admin-website.md).';
  static const signInFailed = 'Sign-in didn’t work';
  static const offline = 'Can’t reach the server. Check the connection.';
  static const retry = 'Try again';
  static const contributions = 'Contributions';
  static const fingerprints = 'Fingerprints';
  static const reports = 'Reports';
  static const catalog = 'Catalog';
  static const comingSoon = 'Coming soon.';
  static const all = 'All';
  static const newSong = 'New song';
  static const editLyrics = 'Correction';
  static const recording = 'Recording';
  static const syncTiming = 'Timing';
  static const queueEmpty = 'Nothing to review.';
  static const pickOne = 'Pick one from the list.';
  static const reload = 'Reload';
  static const resubmitted = 'Resubmitted';
  static const olderVersion =
      'Based on an older version of the song; check it still fits.';
  static const lastNote = 'Last review';
  static const current = 'Now in the catalog';
  static const submitted = 'Submitted';
  static const changes = 'Changes';
  static const noChanges = 'No line changes (details only).';
  static const losesTimings =
      'Approving drops the timing of these recordings (line count changed):';
  static const timing = 'Timing';
  static const noTiming = 'No timing.';
  static const note = 'Note to the contributor';
  static const noteRequired = 'Say what needs to change.';
  static const approve = 'Approve';
  static const requestChanges = 'Request changes';
  static const reject = 'Reject';
  static const approved = 'Approved and published.';
  static const sentBack = 'Sent back with your note.';
  static const rejected = 'Rejected.';
  static const alreadyReviewed = 'Someone already reviewed this one.';
  static const ownContribution = 'You can’t review your own contribution.';
  static const songGone = 'The song is hidden or gone; it can’t be changed.';
  static const unknownArtist = 'Unknown artist';
  static const byAuthor = 'by';
  static const anonymous = 'someone';
  static const fingerprintsEmpty =
      'No fingerprints waiting. (Uploads from phones are paused.)';
  static const installs = 'phones';
  static const hashes = 'hashes';
  static const open = 'Open';
  static const resolved = 'Resolved';
  static const dismissed = 'Dismissed';
  static const resolve = 'Resolve';
  static const dismiss = 'Dismiss';
  static const openSong = 'Open song';
  static const reportsEmpty = 'No reports here.';
  static const songRemoved = 'Song removed';
  static const wrongWords = 'Wrong words';
  static const wrongTiming = 'Wrong timing';
  static const wrongSong = 'Wrong song';
  static const otherReason = 'Other';
  static const search = 'Search by title, artist or id';
  static const noSongs = 'No songs found.';
  static const loadMore = 'Load more';
  static const hidden = 'Hidden';
  static const hide = 'Hide';
  static const restore = 'Restore';
  static const hideTitle = 'Hide this song?';
  static const hideBody =
      'Listeners stop seeing it when their song list next refreshes. '
      'You can restore it later.';
  static const cancel = 'Cancel';
  static const songHidden = 'Hidden from listeners.';
  static const songRestored = 'Shown to listeners again.';
  static const version = 'version';
  static const lines = 'lines';
  static const recordings = 'Recordings';
  static const synced = 'synced';
  static const notSynced = 'not synced';
}
