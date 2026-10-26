import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/collections_dao.dart';
import 'package:zema/features/library/application/playlists.dart';
import 'package:zema/features/library/presentation/widgets/playlist_collage.dart';
import 'package:zema/features/library/presentation/widgets/track_art.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

Playlist _playlist(List<String?> albums) {
  final tracks = [
    for (final (i, album) in albums.indexed)
      Track.fromScan(i + 1, scannedAudio(i + 1, '/m/$i.mp3', album: album)),
  ];
  return Playlist.of(
    StoredPlaylist(
      id: 1,
      name: 'Kidase',
      description: null,
      trackIds: [for (final t in tracks) t.id],
    ),
    {for (final t in tracks) t.id: t},
  );
}

Future<void> _pump(WidgetTester tester, Playlist playlist) => pumpThemed(
  tester,
  ProviderScope(
    overrides: libraryOverrides(),
    child: Center(child: PlaylistCollage(playlist: playlist, size: 100)),
  ),
);

void main() {
  testWidgets('four albums: a 2×2 grid of covers', (tester) async {
    await _pump(tester, _playlist(['A', 'B', 'C', 'D', 'E']));

    final arts = tester.widgetList<TrackArt>(find.byType(TrackArt)).toList();
    expect([for (final a in arts) a.track.id], [1, 2, 3, 4]);
    expect(arts.every((a) => a.size == 50), isTrue);
    expect(tester.getSize(find.byType(PlaylistCollage)), const Size(100, 100));
  });

  testWidgets('fewer albums: the first song\'s cover', (tester) async {
    await _pump(tester, _playlist(['A', 'A', 'B']));

    final art = tester.widget<TrackArt>(find.byType(TrackArt));
    expect(art.track.id, 1);
    expect(art.size, 100);
  });

  testWidgets('empty: a playlist icon', (tester) async {
    await _pump(tester, _playlist([]));

    expect(find.byType(TrackArt), findsNothing);
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
  });
}
