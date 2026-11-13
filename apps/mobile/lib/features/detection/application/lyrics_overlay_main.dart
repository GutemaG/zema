import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lyrics_overlay_sync.dart';

Future<void> runLyricsOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  container.listen(lyricsOverlaySyncProvider, (_, _) {});
}
