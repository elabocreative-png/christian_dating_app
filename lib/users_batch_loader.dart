import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches user documents by id in Firestore `whereIn` chunks (max 30 per query).
abstract final class UsersBatchLoader {
  static const int _whereInLimit = 30;

  static Future<Map<String, Map<String, dynamic>>> fetchByIds(
    Iterable<String> userIds,
  ) async {
    final ids = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return {};

    final usersRef = FirebaseFirestore.instance.collection('users');
    final results = <String, Map<String, dynamic>>{};

    for (var i = 0; i < ids.length; i += _whereInLimit) {
      final end = i + _whereInLimit > ids.length ? ids.length : i + _whereInLimit;
      final chunk = ids.sublist(i, end);

      final snapshot = await usersRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        results[doc.id] = doc.data();
      }
    }

    return results;
  }
}
