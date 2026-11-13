import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../lyrics/presentation/match_lyrics_sheet.dart';
import '../application/detected_song.dart';

Future<SongIdentity?> showChooseDetectedSongSheet(
  BuildContext context,
  DetectedSong detected,
) => showModalBottomSheet<SongIdentity>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ChooseDetectedSongSheet(detected: detected),
);

class ChooseDetectedSongSheet extends ConsumerWidget {
  const ChooseDetectedSongSheet({super.key, required this.detected});

  final DetectedSong detected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detected = this.detected;
    return SongPickerSheet(
      title: AppLocalizations.of(context).detectedChooseTitle,
      subtitle: detected.playback.title,
      suggestions: detected is DetectedUnsure ? detected.candidates : const [],
      checkedId: detected is DetectedMatch ? detected.song.id : null,
      onPick: (song) => ref
          .read(detectedMatchControllerProvider)
          .confirm(detected.playback, song),
    );
  }
}
