// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detected_matches_dao.dart';

// ignore_for_file: type=lint
mixin _$DetectedMatchesDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $DetectedMatchesTable get detectedMatches => attachedDatabase.detectedMatches;
  DetectedMatchesDaoManager get managers => DetectedMatchesDaoManager(this);
}

class DetectedMatchesDaoManager {
  final _$DetectedMatchesDaoMixin _db;
  DetectedMatchesDaoManager(this._db);
  $$DetectedMatchesTableTableManager get detectedMatches =>
      $$DetectedMatchesTableTableManager(
        _db.attachedDatabase,
        _db.detectedMatches,
      );
}
