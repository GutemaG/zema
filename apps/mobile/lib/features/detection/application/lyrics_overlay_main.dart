import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lyrics_overlay_sync.dart';
import 'player_overlay.dart';

Future<void> runLyricsOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    overrides: [playerOverlayProvider.overrideWithValue(null)],
  );
  container.listen(lyricsOverlaySyncProvider, (_, _) {});
}
