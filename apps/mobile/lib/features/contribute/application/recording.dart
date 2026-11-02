import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../data/shared_audio.dart';
import '../data/sync_player.dart';
import '../data/youtube_info.dart';

/// Looks up YouTube videos. Tests override it.
final youtubeInfoServiceProvider = Provider<YoutubeInfoService>(
  (ref) => OEmbedYoutubeInfoService(
    () async => Directory(
      p.join((await getApplicationSupportDirectory()).path, 'youtube'),
    ),
  ),
);

/// [videoId]'s title and thumbnail; null offline or when there's no such
/// video.
final youtubeInfoProvider = FutureProvider.autoDispose
    .family<YoutubeInfo?, String>(
      (ref, videoId) => ref.watch(youtubeInfoServiceProvider).load(videoId),
    );

/// Audio files shared to Zema. Tests override it.
final shareReceiverProvider = Provider<ShareReceiver>(
  (ref) =>
      Platform.isAndroid ? AndroidShareReceiver() : const NoShareReceiver(),
);

/// Each audio file shared to Zema: the one that started the app, then
/// those shared while it runs.
final incomingSharesProvider = StreamProvider<SharedAudio>((ref) async* {
  final receiver = ref.watch(shareReceiverProvider);
  if (await receiver.takeInitial() case final audio?) yield audio;
  yield* receiver.shares;
});

/// Starts a new-song draft at S20 with shared [audio] as its recording;
/// returns its id.
Future<int> startSharedDraft(WidgetRef ref, SharedAudio audio) => ref
    .read(databaseProvider)
    .draftsDao
    .create(
      ContributionDraft(
        recording: Recording(
          id: newRecordingId(),
          songId: '',
          source: RecordingSource.telegram,
          duration: audio.duration,
          fileName: audio.name,
        ),
        audioPath: audio.path,
        step: DraftStep.recording,
      ),
      now: clock.now(),
    );

/// Makes the sync editor's own player. Tests override it.
final syncPlayerProvider = Provider<SyncPlayer Function()>(
  (ref) => JustAudioSyncPlayer.new,
);
