import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'own_copies_dao.g.dart';

/// The user's own copy of a contribution waiting for review (see
/// [OwnCopies]).
class OwnCopy {
  const OwnCopy({
    required this.contributionId,
    required this.kind,
    required this.song,
    required this.submittedAt,
    this.recording,
    this.timing,
    this.trackId,
    this.audioPath,
  });

  final String contributionId;
  final ContributionKind kind;
  final Song song;
  final Recording? recording;

  /// Null when it was sent without timings.
  final SyncTiming? timing;

  /// The local track it was made for, if any.
  final int? trackId;

  /// Zema's copy of a file shared to it, if any.
  final String? audioPath;
  final DateTime submittedAt;
}

/// Own copies of contributions waiting for review (see [OwnCopies]).
@DriftAccessor(tables: [OwnCopies])
class OwnCopiesDao extends DatabaseAccessor<ZemaDatabase>
    with _$OwnCopiesDaoMixin {
  OwnCopiesDao(super.attachedDatabase);

  /// Every copy, last sent first. Copies this app can't read are left out.
  Stream<List<OwnCopy>> watchAll() => _ordered().watch().map(_toCopies);

  /// Every copy, last sent first.
  Future<List<OwnCopy>> all() async => _toCopies(await _ordered().get());

  /// Keeps [copy]; one with the same contribution id is replaced.
  Future<void> add(OwnCopy copy) {
    final row = OwnCopiesCompanion.insert(
      contributionId: copy.contributionId,
      kind: copy.kind.wire,
      song: jsonEncode(copy.song.toJson()),
      recording: Value(_encode(copy.recording?.toJson())),
      timing: Value(_encode(copy.timing?.toJson())),
      trackId: Value(copy.trackId),
      audioPath: Value(copy.audioPath),
      submittedAt: copy.submittedAt.toUtc(),
    );
    return into(ownCopies).insert(
      row,
      onConflict: DoUpdate((_) => row, target: [ownCopies.contributionId]),
    );
  }

  Future<void> remove(String contributionId) => (delete(
    ownCopies,
  )..where((c) => c.contributionId.equals(contributionId))).go();

  Future<void> clear() => delete(ownCopies).go();

  /// Zema's copies of shared audio files the copies keep.
  Future<List<String>> audioPaths() async => [
    for (final row in await select(ownCopies).get()) ?row.audioPath,
  ];

  SimpleSelectStatement<$OwnCopiesTable, OwnCopyRow> _ordered() =>
      select(ownCopies)..orderBy([
        (c) => OrderingTerm.desc(c.submittedAt),
        (c) => OrderingTerm.desc(c.id),
      ]);

  static String? _encode(Map<String, Object?>? json) =>
      json == null ? null : jsonEncode(json);

  static List<OwnCopy> _toCopies(List<OwnCopyRow> rows) => [
    for (final row in rows) ?_toCopy(row),
  ];

  static OwnCopy? _toCopy(OwnCopyRow row) {
    try {
      return OwnCopy(
        contributionId: row.contributionId,
        kind: ContributionKind.fromWire(row.kind),
        song: Song.fromJson(jsonDecode(row.song)),
        recording: switch (row.recording) {
          null => null,
          final json => Recording.fromJson(jsonDecode(json)),
        },
        timing: switch (row.timing) {
          null => null,
          final json => SyncTiming.fromJson(jsonDecode(json)),
        },
        trackId: row.trackId,
        audioPath: row.audioPath,
        submittedAt: row.submittedAt.toUtc(),
      );
    } on Object {
      return null;
    }
  }
}
