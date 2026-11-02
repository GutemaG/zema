import 'dart:async';
import 'dart:typed_data';

import 'package:zema/features/contribute/data/shared_audio.dart';
import 'package:zema/features/contribute/data/youtube_info.dart';

/// [YoutubeInfoService] answering from [videos]; any other id is offline.
class FakeYoutubeInfoService implements YoutubeInfoService {
  FakeYoutubeInfoService([this.videos = const {}]);

  final Map<String, YoutubeInfo> videos;
  final looked = <String>[];

  @override
  Future<YoutubeInfo?> load(String videoId) async {
    looked.add(videoId);
    return videos[videoId];
  }
}

/// A one-pixel PNG, for thumbnails.
final testThumbnail = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// [ShareReceiver] with an [initial] file and [share] for later ones.
class FakeShareReceiver implements ShareReceiver {
  FakeShareReceiver({this.initial});

  SharedAudio? initial;
  final _shares = StreamController<SharedAudio>.broadcast();

  void share(SharedAudio audio) => _shares.add(audio);

  @override
  Future<SharedAudio?> takeInitial() async {
    final audio = initial;
    initial = null;
    return audio;
  }

  @override
  Stream<SharedAudio> get shares => _shares.stream;
}
