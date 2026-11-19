import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One value the user picks (a filter, a selected row), starting at
/// [initial].
class Choice<T> extends Notifier<T> {
  Choice(this.initial);

  final T initial;

  @override
  T build() => initial;

  void pick(T value) => state = value;
}
