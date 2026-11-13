import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/library_dao.dart';
import '../../../app/preferences_provider.dart';
import '../../account/application/account_providers.dart';
import '../../catalog/application/report_sender.dart';
import '../../catalog/data/catalog_lyrics_repository.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../data/audio_decoder.dart';

final _log = Logger('identify.shared');

/// The server index's fingerprint of the file at [uri] (at
/// [FingerprintDensity.catalog], made off the UI isolate), or null when it
/// can't be decoded.
Future<AudioFingerprint?> catalogFingerprintOf(
  AudioDecoder decoder,
  String uri,
) async {
  final audio = await decoder.decode(uri);
  if (audio == null) return null;
  final moved = TransferableTypedData.fromList([audio.pcm16]);
  return Isolate.run(
    () => const Fingerprinter().fingerprint(
      pcm16ToFloat(moved.materialize().asUint8List()),
    ),
  );
}

/// Sends the fingerprint of a contribution's file recording (intent 009,
/// FR-2), so the song can be identified by sound once it is approved.
class ContributionFingerprints {
  ContributionFingerprints({
    required this._repository,
    required this._decoder,
    required this._library,
  });

  final ContributionRepository _repository;
  final AudioDecoder _decoder;
  final LibraryDao _library;

  /// Attaches the fingerprint of [draft]'s file to contribution [id]: its
  /// library track's, or the shared file's. Nothing for a YouTube recording
  /// or none.
  Future<void> attach(String id, ContributionDraft draft) async {
    final recording = draft.recording;
    if (recording == null || recording.source == RecordingSource.youtube) {
      return;
    }
    final uri = switch ((draft.trackId, draft.audioPath)) {
      (final int trackId, _) => (await _library.fileTrack(trackId))?.uri,
      (_, final String path) => Uri.file(path).toString(),
      _ => null,
    };
    if (uri == null) return;
    final fingerprint = await catalogFingerprintOf(_decoder, uri);
    if (fingerprint == null) {
      _log.info('No fingerprint for contribution $id: unreadable file');
      return;
    }
    await _repository.attachFingerprint(id, fingerprint);
  }
}

final contributionFingerprintsProvider = Provider<ContributionFingerprints?>((
  ref,
) {
  final repository = ref.watch(contributionRepositoryProvider);
  if (repository == null) return null;
  return ContributionFingerprints(
    repository: repository,
    decoder: ref.watch(audioDecoderProvider),
    library: ref.watch(databaseProvider).libraryDao,
  );
});

/// Whether this phone shares the fingerprints of library songs the catalog
/// has none for; null until the user is asked.
final shareFingerprintsProvider =
    NotifierProvider<ShareFingerprintsSetting, bool?>(
      ShareFingerprintsSetting.new,
    );

class ShareFingerprintsSetting extends Notifier<bool?> {
  static const key = 'identify.shareFingerprints';

  @override
  bool? build() => ref.watch(sharedPreferencesProvider).getBool(key);

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(key, on);
  }
}

/// A library file, and the catalog recording its song's lyrics are timed
/// by.
typedef ShareCandidate = ({Track track, Recording recording});

/// How far a file's length may be from its recording's to be shared.
const shareLengthTolerance = Duration(seconds: 2);

/// Shares library fingerprints with the catalog (intent 009, FR-2): for
/// each file linked to a recording that has none, once per recording.
class FingerprintSharer {
  FingerprintSharer({
    required this._catalog,
    required this._decoder,
    required this._preferences,
    required this._candidates,
  });

  /// The recordings this install shared, or that needed none.
  static const doneKey = 'identify.sharedRecordings';

  final AudioCatalog _catalog;
  final AudioDecoder _decoder;
  final SharedPreferences _preferences;
  final Future<List<ShareCandidate>> Function() _candidates;
  Future<int>? _sharing;

  Set<String> get _done => {...?_preferences.getStringList(doneKey)};

  Future<void> _markDone(Iterable<String> ids) =>
      _preferences.setStringList(doneKey, [..._done, ...ids]);

  /// The candidates whose recording the catalog has no fingerprint for, one
  /// per recording. Throws [ZemaFailure]s.
  Future<List<ShareCandidate>> needed() async {
    final done = _done;
    final open = <String, ShareCandidate>{};
    for (final candidate in await _candidates()) {
      final id = candidate.recording.id;
      if (!done.contains(id)) open.putIfAbsent(id, () => candidate);
    }
    if (open.isEmpty) return const [];
    final ids = open.keys.take(200).toList();
    final missing = await _catalog.missingFingerprints(ids);
    await _markDone(ids.where((id) => !missing.contains(id)));
    return [
      for (final id in ids)
        if (missing.contains(id)) open[id]!,
    ];
  }

  /// Shares up to [limit] fingerprints (about 400 KB each); returns how
  /// many were sent. Stops offline and at the daily limit.
  Future<int> share({int limit = 5}) =>
      _sharing ??= _share(limit).whenComplete(() => _sharing = null);

  Future<int> _share(int limit) async {
    var sent = 0;
    final install = installId(_preferences);
    for (final candidate in (await needed()).take(limit)) {
      final recording = candidate.recording.id;
      final fingerprint = await catalogFingerprintOf(
        _decoder,
        candidate.track.uri,
      );
      if (fingerprint != null) {
        try {
          await _catalog.shareFingerprint(
            recording,
            fingerprint,
            installId: install,
          );
          sent++;
        } on NetworkFailure {
          return sent;
        } on RateLimitFailure {
          return sent;
        } on ZemaFailure catch (e) {
          _log.warning('Fingerprint for $recording refused', e);
        }
      }
      await _markDone([recording]);
    }
    return sent;
  }
}

/// The library's files linked to a catalog song on the phone whose first
/// recording (the one its lyrics are timed by) is as long as the file.
Future<List<ShareCandidate>> shareCandidates(Ref ref) async {
  final links = await ref
      .read(lyricsLinksRepositoryProvider)
      .watchLinks()
      .first;
  final tracks = await ref.read(databaseProvider).libraryDao.allTracks();
  final lyrics = ref.read(lyricsRepositoryProvider);
  final recordings = <String, Recording?>{};
  return [
    for (final track in tracks)
      if (!track.missing)
        if (links[track.id]?.songId case final songId?)
          if (recordings[songId] ??= usedRecording(
                await lyrics.recordings(songId),
              )
              case Recording(:final duration?) && final recording
              when (duration - track.duration).abs() <= shareLengthTolerance)
            (track: track, recording: recording),
  ];
}

final fingerprintSharerProvider = Provider<FingerprintSharer?>((ref) {
  final catalog = ref.watch(audioCatalogProvider);
  if (catalog == null) return null;
  return FingerprintSharer(
    catalog: catalog,
    decoder: ref.watch(audioDecoderProvider),
    preferences: ref.watch(sharedPreferencesProvider),
    candidates: () => shareCandidates(ref),
  );
});

/// Whether to ask the user about sharing: not asked yet, and some library
/// songs could help the catalog.
final askShareFingerprintsProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(shareFingerprintsProvider) != null) return false;
  final sharer = ref.watch(fingerprintSharerProvider);
  if (sharer == null) return false;
  try {
    return (await sharer.needed()).isNotEmpty;
  } on ZemaFailure {
    return false;
  }
});

/// Shares fingerprints when Zema starts and when sharing is turned on.
/// Kept alive by the app shell.
final fingerprintShareSyncProvider = Provider<void>((ref) {
  if (ref.watch(shareFingerprintsProvider) != true) return;
  final sharer = ref.watch(fingerprintSharerProvider);
  if (sharer == null) return;
  unawaited(
    sharer.share().then<void>(
      (sent) => _log.info('Shared $sent fingerprints'),
      onError: (Object e) => _log.warning('Sharing fingerprints failed', e),
    ),
  );
});
