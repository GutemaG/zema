import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/backup_dao.dart';
import '../../../app/database/zema_database.dart';
import '../../../app/theme/zema_palette.dart';
import '../../settings/data/app_settings.dart';

/// Builds the backup document from the database and the settings: library
/// data the user made, never audio, play history, the queue, cached lyrics
/// or any path but a file name. Dates are in UTC, as the document stores
/// them.
class BackupBuilder {
  BackupBuilder(this._dao);

  final BackupDao _dao;

  Future<BackupDocument> build(AppSettings settings, {DateTime? now}) async {
    final rows = await _dao.read();
    return BackupDocument(
      createdAt: (now ?? DateTime.now()).toUtc(),
      favorites: [
        for (final (:track, :addedAt) in rows.favorites)
          BackupFavorite(track: identityOf(track), addedAt: addedAt.toUtc()),
      ],
      playlists: [
        for (final (:playlist, :tracks) in rows.playlists)
          BackupPlaylist(
            name: playlist.name,
            description: playlist.description,
            createdAt: playlist.createdAt.toUtc(),
            tracks: [for (final track in tracks) identityOf(track)],
          ),
      ],
      lyricsChoices: [
        for (final (:track, :songId) in rows.manualLinks)
          BackupLyricsChoice(track: identityOf(track), songId: songId),
      ],
      hiddenFolders: [
        for (final folder in rows.hiddenFolders) storageRelativePath(folder),
      ],
      hiddenTracks: [for (final track in rows.hiddenTracks) identityOf(track)],
      settings: backupSettings(settings),
    );
  }
}

/// [row]'s identity, as [TrackIdentity.ofTrack] gives it.
TrackIdentity identityOf(TrackRow row) => TrackIdentity(
  title: row.title,
  artist: row.artist,
  album: row.album,
  durationMs: row.durationMs,
  fileName: fileNameOf(row.path),
);

final _storageVolume = RegExp(
  r'^(/storage/emulated/\d+|/storage/[^/]+|/sdcard)(/|$)',
);

/// [path] without its storage volume: `/storage/emulated/0/Recordings` is
/// `Recordings`, so a backup names the same folder on any phone. Other
/// paths are kept whole.
String storageRelativePath(String path) =>
    path.replaceFirst(_storageVolume, '');

/// [settings] as the backup's plain values. [settingsFromBackup] reads them
/// back.
Map<String, Object?> backupSettings(AppSettings settings) => {
  'palette': settings.palette.name,
  'themeMode': settings.themeMode.name,
  'language': ?settings.languageCode,
  'minTrackSeconds': settings.minTrackSeconds,
  'sleepTimerDefault': settings.sleepTimerDefault.name,
  'pauseOnUnplug': settings.pauseOnUnplug,
  'duckOnInterruption': settings.duckOnInterruption,
  'gapless': settings.gapless,
};

/// [current] with the backup's [values] applied. Missing, unknown or
/// invalid values keep the current setting.
AppSettings settingsFromBackup(
  Map<String, Object?> values,
  AppSettings current,
) {
  T? byName<T extends Enum>(List<T> all, Object? name) {
    for (final value in all) {
      if (value.name == name) return value;
    }
    return null;
  }

  return AppSettings(
    palette: byName(ZemaPalette.values, values['palette']) ?? current.palette,
    themeMode:
        byName(ThemeMode.values, values['themeMode']) ?? current.themeMode,
    languageCode: switch (values['language']) {
      final String code => code,
      _ => current.languageCode,
    },
    minTrackSeconds: switch (values['minTrackSeconds']) {
      final int seconds when AppSettings.minTrackChoices.contains(seconds) =>
        seconds,
      _ => current.minTrackSeconds,
    },
    sleepTimerDefault:
        byName(SleepTimerDefault.values, values['sleepTimerDefault']) ??
        current.sleepTimerDefault,
    pauseOnUnplug: switch (values['pauseOnUnplug']) {
      final bool value => value,
      _ => current.pauseOnUnplug,
    },
    duckOnInterruption: switch (values['duckOnInterruption']) {
      final bool value => value,
      _ => current.duckOnInterruption,
    },
    gapless: switch (values['gapless']) {
      final bool value => value,
      _ => current.gapless,
    },
  );
}

/// The builder over [database].
BackupBuilder backupBuilderOf(ZemaDatabase database) =>
    BackupBuilder(database.backupDao);
