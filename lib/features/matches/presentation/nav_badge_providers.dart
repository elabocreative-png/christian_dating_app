import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/services/match_read_state.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_unread.dart';

typedef MatchDocEntry = ({String id, Map<String, dynamic> data});

final likesIncomingStreamProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>(
  (ref, uid) {
    return FirebaseFirestore.instance
        .collection('likes')
        .where('toUserId', isEqualTo: uid)
        .snapshots();
  },
);

final likedYouCountProvider = Provider.family<int, String>((ref, uid) {
  final snapshot = ref.watch(likesIncomingStreamProvider(uid));
  return snapshot.when(
    data: (snap) => likedYouVisibleIncomingLikes(snap.docs).length,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

final matchesDocsStreamProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>(
  (ref, uid) {
    return FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: uid)
        .snapshots();
  },
);

final matchesDocsProvider = Provider.family<List<MatchDocEntry>, String>(
  (ref, uid) {
    final snapshot = ref.watch(matchesDocsStreamProvider(uid));
    return snapshot.when(
      data: (snap) =>
          snap.docs.map((d) => (id: d.id, data: d.data())).toList(),
      loading: () => const [],
      error: (error, stackTrace) => const [],
    );
  },
);

final unreadMessageThreadsProvider = Provider.family<int, String>((ref, uid) {
  final docs = ref.watch(matchesDocsProvider(uid));
  final sessionRead = ref.watch(matchReadStateProvider);
  return MatchUnread.unreadMessageThreadsCountFromDocs(
    docs,
    uid,
    sessionReadMatchIds: sessionRead,
  );
});
