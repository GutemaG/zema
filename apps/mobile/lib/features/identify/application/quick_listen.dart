import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quick_launch.dart';
import 'listen_controller.dart';
import 'listen_history.dart';

final quickListenHostProvider = Provider<QuickListenHost?>((ref) => null);

final launchReceiverProvider = Provider<LaunchReceiver>(
  (ref) =>
      Platform.isAndroid ? AndroidLaunchReceiver() : const NoLaunchReceiver(),
);

final incomingLaunchesProvider = StreamProvider<LaunchRequest>((ref) async* {
  final receiver = ref.watch(launchReceiverProvider);
  if (await receiver.takeInitial() case final request?) yield request;
  yield* receiver.launches;
});

final homeWidgetProvider = Provider<HomeWidget>(
  (ref) =>
      Platform.isAndroid ? const AndroidHomeWidget() : const NoHomeWidget(),
);

final homeWidgetSyncProvider = Provider<void>((ref) {
  final widget = ref.watch(homeWidgetProvider);
  ref.listen(listenHistoryProvider, (_, next) {
    if (next case AsyncData(:final value)) {
      final last = value.firstOrNull;
      widget.showLast(title: last?.title, artist: last?.artist);
    }
  });
});

final pendingMatchProvider = NotifierProvider<PendingMatch, ListenFound?>(
  PendingMatch.new,
);

class PendingMatch extends Notifier<ListenFound?> {
  @override
  ListenFound? build() => null;

  void set(ListenFound? found) => state = found;
}
