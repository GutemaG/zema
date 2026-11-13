// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fingerprints_dao.dart';

// ignore_for_file: type=lint
mixin _$FingerprintsDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $TrackFingerprintsTable get trackFingerprints =>
      attachedDatabase.trackFingerprints;
  $CatalogFingerprintsTable get catalogFingerprints =>
      attachedDatabase.catalogFingerprints;
  FingerprintsDaoManager get managers => FingerprintsDaoManager(this);
}

class FingerprintsDaoManager {
  final _$FingerprintsDaoMixin _db;
  FingerprintsDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$TrackFingerprintsTableTableManager get trackFingerprints =>
      $$TrackFingerprintsTableTableManager(
        _db.attachedDatabase,
        _db.trackFingerprints,
      );
  $$CatalogFingerprintsTableTableManager get catalogFingerprints =>
      $$CatalogFingerprintsTableTableManager(
        _db.attachedDatabase,
        _db.catalogFingerprints,
      );
}
