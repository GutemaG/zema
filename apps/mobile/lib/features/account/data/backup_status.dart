import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why the last backup didn't happen.
enum BackupError {
  /// The server couldn't be reached.
  offline,

  /// The server refused or failed.
  failed,

  /// The cloud holds a backup this phone didn't make or restore (another
  /// phone's, or one kept by Start fresh). Replacing it needs the user's
  /// say-so.
  otherBackup,
}

/// This phone's backup state for one user.
@immutable
class BackupStatus {
  const BackupStatus({
    this.lastBackupAt,
    this.lastError,
    this.autoBackup = true,
    this.syncedAt,
    this.contentHash,
  });

  /// Reads [toJson]'s output; anything unreadable is left at its default.
  factory BackupStatus.fromJson(Map<String, Object?> json) => BackupStatus(
    lastBackupAt: _time(json['lastBackupAt']),
    lastError: BackupError.values.asNameMap()[json['lastError']],
    autoBackup: json['autoBackup'] is bool ? json['autoBackup']! as bool : true,
    syncedAt: _time(json['syncedAt']),
    contentHash: json['contentHash'] is int
        ? json['contentHash']! as int
        : null,
  );

  /// When this phone last backed up (the server's time).
  final DateTime? lastBackupAt;
  final BackupError? lastError;

  /// Back up once a day on Wi-Fi; on by default after sign-in.
  final bool autoBackup;

  /// The server time of the cloud backup this phone last saved or
  /// restored. A cloud backup with another time came from elsewhere.
  final DateTime? syncedAt;

  /// [backupContentHash] of the last document saved, so an unchanged
  /// library isn't uploaded again.
  final int? contentHash;

  BackupStatus copyWith({
    DateTime? lastBackupAt,
    BackupError? Function()? lastError,
    bool? autoBackup,
    DateTime? syncedAt,
    int? contentHash,
  }) => BackupStatus(
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    lastError: lastError == null ? this.lastError : lastError(),
    autoBackup: autoBackup ?? this.autoBackup,
    syncedAt: syncedAt ?? this.syncedAt,
    contentHash: contentHash ?? this.contentHash,
  );

  Map<String, Object?> toJson() => {
    'lastBackupAt': ?lastBackupAt?.toUtc().toIso8601String(),
    'lastError': ?lastError?.name,
    'autoBackup': autoBackup,
    'syncedAt': ?syncedAt?.toUtc().toIso8601String(),
    'contentHash': ?contentHash,
  };

  @override
  bool operator ==(Object other) =>
      other is BackupStatus &&
      other.lastBackupAt == lastBackupAt &&
      other.lastError == lastError &&
      other.autoBackup == autoBackup &&
      other.syncedAt == syncedAt &&
      other.contentHash == contentHash;

  @override
  int get hashCode =>
      Object.hash(lastBackupAt, lastError, autoBackup, syncedAt, contentHash);

  @override
  String toString() => 'BackupStatus(${toJson()})';
}

DateTime? _time(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// [BackupStatus] per user in shared preferences, at `backup.<userId>`.
class BackupStatusStore {
  BackupStatusStore(this._prefs);

  final SharedPreferences _prefs;

  static String key(String userId) => 'backup.$userId';

  /// [userId]'s status; the defaults when none is saved or it can't be read.
  /// Reloads first, so a backup made in the background is seen.
  Future<BackupStatus> read(String userId) async {
    await _prefs.reload();
    return readCached(userId);
  }

  /// [read] without reloading, for the first frame.
  BackupStatus readCached(String userId) {
    final json = _prefs.getString(key(userId));
    if (json == null) return const BackupStatus();
    try {
      return BackupStatus.fromJson(jsonDecode(json) as Map<String, Object?>);
    } on Object {
      return const BackupStatus();
    }
  }

  Future<void> write(String userId, BackupStatus status) =>
      _prefs.setString(key(userId), jsonEncode(status.toJson()));

  Future<void> remove(String userId) => _prefs.remove(key(userId));
}
