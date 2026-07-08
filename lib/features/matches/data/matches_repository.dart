import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

/// Data access for the matches list and incoming likes.
///
/// Returns app types (records / plain maps) so the presentation layer never
/// touches cloud_firestore directly.
class MatchesRepository {
  MatchesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Live matches the user is part of.
  Stream<List<MatchEntry>> watchMatches(String uid) {
    return _firestore
        .collection('matches')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => (id: d.id, data: d.data())).toList());
  }

  /// Live incoming likes addressed to the user (raw like data maps).
  Stream<List<Map<String, dynamic>>> watchIncomingLikes(String uid) {
    return _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository();
});
