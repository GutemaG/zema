import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/drafts_dao.dart';
import '../data/shared_audio.dart';

final _log = Logger('contribute.drafts');

/// How long the editor waits after a change before saving it.
const draftSaveDelay = Duration(milliseconds: 300);

/// The saved drafts, last changed first (S05).
final draftsProvider = StreamProvider<List<SavedDraft>>(
  (ref) => ref.watch(databaseProvider).draftsDao.watchAll(),
);

/// Starts a new draft (a new song, unless [draft] says otherwise) and
/// returns its id.
Future<int> startDraft(
  WidgetRef ref, {
  ContributionDraft draft = const ContributionDraft(),
}) => ref.read(databaseProvider).draftsDao.create(draft, now: clock.now());

/// Deletes draft [id], and Zema's copy of a file shared for it unless a
/// contribution sent with it still keeps it.
Future<void> deleteDraft(WidgetRef ref, int id) async {
  final database = ref.read(databaseProvider);
  final path = (await database.draftsDao.get(id))?.draft.audioPath;
  await database.draftsDao.remove(id);
  if (!(await database.ownCopiesDao.audioPaths()).contains(path)) {
    await deleteSharedAudio(path);
  }
}

/// One draft being edited: loads it, applies each change at once, and saves
/// it [draftSaveDelay] after the last change, at once when the app goes to
/// the background, and when the editor closes. Null while loading, or when
/// the draft no longer exists.
final draftEditorProvider = AsyncNotifierProvider.autoDispose
    .family<DraftEditor, ContributionDraft?, int>(DraftEditor.new);

class DraftEditor extends AsyncNotifier<ContributionDraft?> {
  DraftEditor(this.id);

  final int id;
  Timer? _timer;
  ContributionDraft? _unsaved;
  Future<void> _saving = Future.value();

  @override
  Future<ContributionDraft?> build() async {
    final dao = ref.read(databaseProvider).draftsDao;
    final lifecycle = AppLifecycleListener(onPause: () => unawaited(flush()));
    ref.onDispose(() {
      lifecycle.dispose();
      _timer?.cancel();
      final unsaved = _unsaved;
      // The provider is gone; save what's left without it.
      if (unsaved != null) {
        _unsaved = null;
        unawaited(_write(dao, unsaved));
      }
    });
    return (await dao.get(id))?.draft;
  }

  /// Applies [change] to the draft; it is saved shortly after.
  void edit(ContributionDraft Function(ContributionDraft draft) change) {
    final current = state.value;
    if (current == null) return;
    final next = change(current);
    if (next == current) return;
    state = AsyncData(next);
    _unsaved = next;
    _timer?.cancel();
    _timer = Timer(draftSaveDelay, () => unawaited(flush()));
  }

  /// Saves a pending change now.
  Future<void> flush() {
    _timer?.cancel();
    final unsaved = _unsaved;
    if (unsaved == null) return _saving;
    _unsaved = null;
    return _write(ref.read(databaseProvider).draftsDao, unsaved);
  }

  Future<void> _write(DraftsDao dao, ContributionDraft draft) =>
      _saving = _saving.then(
        (_) => dao
            .save(id, draft, now: clock.now())
            .then<void>(
              (_) {},
              onError: (Object e) => _log.warning('Saving draft $id failed', e),
            ),
      );
}
