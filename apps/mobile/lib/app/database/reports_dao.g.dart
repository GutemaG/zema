// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_dao.dart';

// ignore_for_file: type=lint
mixin _$ReportsDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $QueuedReportsTable get queuedReports => attachedDatabase.queuedReports;
  ReportsDaoManager get managers => ReportsDaoManager(this);
}

class ReportsDaoManager {
  final _$ReportsDaoMixin _db;
  ReportsDaoManager(this._db);
  $$QueuedReportsTableTableManager get queuedReports =>
      $$QueuedReportsTableTableManager(_db.attachedDatabase, _db.queuedReports);
}
