import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'drafts_dao.g.dart';

/// A saved contribution in progress, as listed on S05.
class SavedDraft {
  const SavedDraft({
    required this.id,
    required this.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final ContributionDraft draft;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Contributions in progress (see [Drafts]).
@DriftAccessor(tables: [Drafts])
class DraftsDao extends DatabaseAccessor<ZemaDatabase> with _$DraftsDaoMixin {
  DraftsDao(super.attachedDatabase);

  /// Every draft, last changed first. Drafts this app can't read (a newer
  /// format) are left out.
  Stream<List<SavedDraft>> watchAll() =>
      (select(drafts)..orderBy([
            (d) => OrderingTerm.desc(d.updatedAt),
            (d) => OrderingTerm.desc(d.id),
          ]))
          .watch()
          .map((rows) => [for (final row in rows) ?_toSaved(row)]);

  Future<SavedDraft?> get(int id) async {
    final row = await (select(
      drafts,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSaved(row);
  }

  /// Saves [draft] as a new draft at [now]; returns its id.
  Future<int> create(ContributionDraft draft, {required DateTime now}) =>
      into(drafts).insert(
        DraftsCompanion.insert(
          kind: draft.kind.wire,
          step: draft.step.name,
          title: draft.title,
          draft: jsonEncode(draft.toJson()),
          createdAt: now.toUtc(),
          updatedAt: now.toUtc(),
        ),
      );

  /// Replaces draft [id] with [draft], changed at [now]. False when it no
  /// longer exists.
  Future<bool> save(
    int id,
    ContributionDraft draft, {
    required DateTime now,
  }) async =>
      await (update(drafts)..where((d) => d.id.equals(id))).write(
        DraftsCompanion(
          kind: Value(draft.kind.wire),
          step: Value(draft.step.name),
          title: Value(draft.title),
          draft: Value(jsonEncode(draft.toJson())),
          updatedAt: Value(now.toUtc()),
        ),
      ) >
      0;

  Future<void> remove(int id) =>
      (delete(drafts)..where((d) => d.id.equals(id))).go();

  Future<void> clear() => delete(drafts).go();

  /// The titles of all drafts, last changed first; empty for untitled ones.
  Future<List<String>> titles() async => [
    for (final row in await (select(
      drafts,
    )..orderBy([(d) => OrderingTerm.desc(d.updatedAt)])).get())
      row.title,
  ];

  static SavedDraft? _toSaved(DraftRow row) {
    try {
      return SavedDraft(
        id: row.id,
        draft: ContributionDraft.fromJson(jsonDecode(row.draft)),
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
    } on Object {
      return null;
    }
  }
}
