import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [a] and [b] joined by [combine]: the first error if either failed,
/// loading until both have data.
AsyncValue<R> combineAsync<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A a, B b) combine,
) {
  for (final value in [a, b]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace!);
  }
  if (a.hasValue && b.hasValue) {
    return AsyncData(combine(a.requireValue, b.requireValue));
  }
  return const AsyncLoading();
}
