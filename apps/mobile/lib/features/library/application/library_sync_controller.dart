import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../data/library_repository.dart';
import 'library_access_controller.dart';
import 'library_providers.dart';

final _log = Logger('library.sync');

enum LibrarySyncPhase { idle, scanning, failed }

class LibrarySyncState {
  const LibrarySyncState({
    this.phase = LibrarySyncPhase.idle,
    this.lastResult,
    this.failure,
  });

  final LibrarySyncPhase phase;

  /// The last successful sync, or null before the first one.
  final LibrarySyncResult? lastResult;

  /// Why the last sync failed, when [phase] is failed.
  final ZemaFailure? failure;

  bool get isScanning => phase == LibrarySyncPhase.scanning;
  bool get hasFailed => phase == LibrarySyncPhase.failed;
}

final librarySyncProvider =
    NotifierProvider<LibrarySyncController, LibrarySyncState>(
      LibrarySyncController.new,
    );

/// Runs library scans: automatically once access is granted (at app start
/// or when the user allows it), and on demand. Only one scan runs at a time.
class LibrarySyncController extends Notifier<LibrarySyncState> {
  Future<void>? _running;

  @override
  LibrarySyncState build() {
    ref.listen(libraryAccessProvider, (previous, next) {
      if (next.value == LibraryAccess.granted &&
          previous?.value != LibraryAccess.granted) {
        // Not during build: sync() changes state.
        scheduleMicrotask(() => unawaited(sync()));
      }
    }, fireImmediately: true);
    return const LibrarySyncState();
  }

  /// Scans now, or returns the scan already running.
  Future<void> sync() => _running ??= _run().whenComplete(() {
    _running = null;
  });

  Future<void> _run() async {
    if (!ref.mounted) return;
    state = LibrarySyncState(
      phase: LibrarySyncPhase.scanning,
      lastResult: state.lastResult,
    );
    try {
      final result = await ref.read(libraryRepositoryProvider).sync();
      if (ref.mounted) state = LibrarySyncState(lastResult: result);
    } on ZemaFailure catch (failure) {
      _log.warning('Library sync failed', failure, null);
      if (!ref.mounted) return;
      state = LibrarySyncState(
        phase: LibrarySyncPhase.failed,
        lastResult: state.lastResult,
        failure: failure,
      );
      if (failure is PermissionFailure) {
        unawaited(ref.read(libraryAccessProvider.notifier).refresh());
      }
    }
  }
}
