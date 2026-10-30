import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/backup_dao.dart';
import '../../../app/database/unmatched_dao.dart';
import '../../../app/database/zema_database.dart';
import '../../../app/theme/zema_palette.dart';
import '../../settings/data/app_settings.dart';

/// Builds the backup document from the database and the settings: library
/// data the user made, never audio, play history, the queue, cached lyrics
/// or any path but a file name. Dates are in UTC, as the document stores
/// them.
///
/// Entries kept from a restore whose songs aren't on this phone ([_unmatched])
/// go back in too, so a backup from this phone doesn't lose them: a playlist
/// entry at its old place in its playlist, if the playlist is still here.
class BackupBuilder {
  BackupBuilder(this._dao, this._unmatched);

  final BackupDao _dao;
  final UnmatchedDao _unmatched;

  Future<BackupDocument> build(AppSettings settings, {DateTime? now}) async {
    final rows = await _dao.read();
    final kept = await _unmatched.all();
    List<UnmatchedEntry> keptOf(BackupEntryKind kind) => [
      for (final e in kept)
        if (e.kind == kind) e,
    ];

    final favorites = [
      for (final (:track, :addedAt) in rows.favorites)
        BackupFavorite(track: identityOf(track), addedAt: addedAt.toUtc()),
    ];
    final favorite = {for (final f in favorites) f.track};
    for (final e in keptOf(BackupEntryKind.favorite)) {
      if (favorite.add(e.track)) {
        favorites.add(BackupFavorite(track: e.track, addedAt: e.addedAt!));
      }
    }

    final keptInPlaylists = keptOf(BackupEntryKind.playlist)
      ..sort((a, b) => a.position!.compareTo(b.position!));
    final playlists = [
      for (final (:playlist, :tracks) in rows.playlists)
        BackupPlaylist(
          name: playlist.name,
          description: playlist.description,
          createdAt: playlist.createdAt.toUtc(),
          tracks: _withKept(
            [for (final track in tracks) identityOf(track)],
            [
              for (final e in keptInPlaylists)
                if (playlistNameKey(e.playlist!) == playlist.nameKey) e,
            ],
          ),
        ),
    ];

    final lyricsChoices = [
      for (final (:track, :songId) in rows.manualLinks)
        BackupLyricsChoice(track: identityOf(track), songId: songId),
    ];
    final chosen = {for (final c in lyricsChoices) c.track};
    for (final e in keptOf(BackupEntryKind.lyricsChoice)) {
      if (chosen.add(e.track)) {
        lyricsChoices.add(BackupLyricsChoice(track: e.track, songId: e.songId));
      }
    }

    final hiddenTracks = [
      for (final track in rows.hiddenTracks) identityOf(track),
    ];
    final hidden = hiddenTracks.toSet();
    for (final e in keptOf(BackupEntryKind.hiddenTrack)) {
      if (hidden.add(e.track)) hiddenTracks.add(e.track);
    }

    return BackupDocument(
      createdAt: (now ?? DateTime.now()).toUtc(),
      favorites: favorites,
      playlists: playlists,
      lyricsChoices: lyricsChoices,
      hiddenFolders: [
        for (final folder in rows.hiddenFolders) storageRelativePath(folder),
      ],
      hiddenTracks: hiddenTracks,
      settings: backupSettings(settings),
    );
  }

  /// [tracks] with [kept] songs put back at their old places (in order of
  /// position, clamped to the end).
  static List<TrackIdentity> _withKept(
    List<TrackIdentity> tracks,
    List<UnmatchedEntry> kept,
  ) {
    final present = tracks.toSet();
    final result = [...tracks];
    for (final e in kept) {
      if (!present.add(e.track)) continue;
      result.insert(e.position!.clamp(0, result.length), e.track);
    }
    return result;
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
    BackupBuilder(database.backupDao, database.unmatchedDao);
