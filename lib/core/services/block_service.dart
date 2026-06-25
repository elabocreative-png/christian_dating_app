import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:christian_dating_app/core/models/block_source.dart';

class BlockedUserRecord {
  const BlockedUserRecord({
    required this.blockedUserId,
    required this.source,
    required this.blockedAt,
  });

  final String blockedUserId;
  final BlockSource source;
  final DateTime blockedAt;
}

/// Persists blocks under `users/{uid}/blocked/{blockedUserId}`.
abstract final class BlockService {
  static CollectionReference<Map<String, dynamic>> _blockedRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocked');
  }

  static Future<Set<String>> fetchBlockedUserIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final snapshot = await _blockedRef(uid).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  static Stream<List<BlockedUserRecord>> streamBlockedRecords() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const []);
    }

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
              blockedAt: _readTimestamp(data['blockedAt']),
            );
          }).toList(),
        );
  }

  static Stream<Set<String>> streamBlockedUserIds() {
    return streamBlockedRecords().map(
      (records) => records.map((record) => record.blockedUserId).toSet(),
    );
  }

  static Future<bool> blockUser({
    required String blockedUserId,
    required BlockSource source,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || blockedUserId.isEmpty || blockedUserId == uid) {
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

  static Future<bool> unblockUser(String blockedUserId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || blockedUserId.isEmpty) return false;

    try {
      await _blockedRef(uid).doc(blockedUserId).delete();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
