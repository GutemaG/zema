import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What one user has been told about their contributions' reviews.
@immutable
class ContributionSeen {
  const ContributionSeen({this.reviewedUntil, this.unseen = const {}});

  /// Reads [toJson]'s output; anything unreadable is left at its default.
  factory ContributionSeen.fromJson(Map<String, Object?> json) =>
      ContributionSeen(
        reviewedUntil: switch (json['reviewedUntil']) {
          final String text => DateTime.tryParse(text),
          _ => null,
        },
        unseen: {
          if (json['unseen'] case final List<Object?> ids)
            for (final id in ids) ?(id is String ? id : null),
        },
      );

  /// The server time of the latest review the user was told about; null
  /// before the first check, which tells nothing (see [firstCheck]).
  final DateTime? reviewedUntil;

  /// Contributions whose status changed since S23 was last opened.
  final Set<String> unseen;

  /// [reviewedUntil] after a first check that found no reviews.
  static final firstCheck = DateTime.utc(2000);

  Map<String, Object?> toJson() => {
    'reviewedUntil': ?reviewedUntil?.toUtc().toIso8601String(),
    'unseen': [...unseen],
  };

  @override
  bool operator ==(Object other) =>
      other is ContributionSeen &&
      other.reviewedUntil == reviewedUntil &&
      setEquals(other.unseen, unseen);

  @override
  int get hashCode =>
      Object.hash(reviewedUntil, Object.hashAllUnordered(unseen));
}

/// [ContributionSeen] per user, in the app's preferences.
class ContributionSeenStore {
  ContributionSeenStore(this._prefs);

  final SharedPreferences _prefs;

  static String key(String userId) => 'contributions.$userId';

  /// [userId]'s state; the defaults when none is saved or it can't be read.
  ContributionSeen read(String userId) {
    final json = _prefs.getString(key(userId));
    if (json == null) return const ContributionSeen();
    try {
      return ContributionSeen.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
    } on Object {
      return const ContributionSeen();
    }
  }

  Future<void> write(String userId, ContributionSeen seen) =>
      _prefs.setString(key(userId), jsonEncode(seen.toJson()));

  Future<void> remove(String userId) => _prefs.remove(key(userId));
}
