import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';
import 'package:christian_dating_app/features/settings/domain/blocked_user_record.dart';

/// Persists blocks under `users/{uid}/blocked/{blockedUserId}`.
class BlockRepository {
  BlockRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) {
    return _db.collection('users').doc(uid).collection('blocked');
  }

  Future<Set<String>> fetchBlockedUserIds(String uid) async {
    final snapshot = await _blockedRef(uid).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Stream<List<BlockedUserRecord>> watchBlockedRecords(String uid) {
    return _blockedRef(uid)
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return BlockedUserRecord(
              blockedUserId: doc.id,
              source: blockSourceFromFirestore(data['source']?.toString()) ??
                  BlockSource.discovery,
              blockedAt:
                  firestoreDateTimeFrom(data['blockedAt']) ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  Stream<Set<String>> watchBlockedUserIds(String uid) {
    return watchBlockedRecords(uid).map(
      (records) => records.map((record) => record.blockedUserId).toSet(),
    );
  }

  Future<bool> blockUser({
    required String uid,
    required String blockedUserId,
    required BlockSource source,
  }) async {
    if (blockedUserId.isEmpty || blockedUserId == uid) {
      return false;
    }

    try {
      await _blockedRef(uid).doc(blockedUserId).set({
        'blockedUserId': blockedUserId,
        'source': source.firestoreValue,
        'blockedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException {
      return false;
    }
  }

  Future<bool> unblockUser({
    required String uid,
    required String blockedUserId,
  }) async {
    if (blockedUserId.isEmpty) return false;

    try {
      await _blockedRef(uid).doc(blockedUserId).delete();
      return true;
    } on FirebaseException {
      return false;
    }
  }
}

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});
