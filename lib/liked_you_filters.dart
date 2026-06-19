import 'package:cloud_firestore/cloud_firestore.dart';

/// True when an incoming like included a message (profile intro, prompt comment, etc.).
///
/// These are delivered to Chats instead of the Liked You grid.
bool isLikedYouMessageIntro(Map<String, dynamic> data) {
  final content = (data['content'] ?? '').toString();
  if (content == 'Profile message') return true;
  final message = (data['message'] ?? '').toString().trim();
  return message.isNotEmpty;
}

/// Incoming likes that should appear on [LikedYouScreen] and the heart tab badge.
List<QueryDocumentSnapshot<Map<String, dynamic>>> likedYouVisibleIncomingLikes(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.where((d) => !isLikedYouMessageIntro(d.data())).toList();
}

/// Incoming likes with a message for the Liked You **Intros** tab.
List<QueryDocumentSnapshot<Map<String, dynamic>>> likedYouIncomingIntros(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.where((d) => isLikedYouMessageIntro(d.data())).toList();
}

/// One outgoing like per target user (newest [createdAt] wins).
List<QueryDocumentSnapshot<Map<String, dynamic>>> likedYouOutgoingLikes(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final byTargetId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

  for (final doc in docs) {
    final targetId = doc.data()['toUserId']?.toString() ?? '';
    if (targetId.isEmpty) continue;

    final existing = byTargetId[targetId];
    if (existing == null) {
      byTargetId[targetId] = doc;
      continue;
    }

    final existingAt = existing.data()['createdAt'];
    final docAt = doc.data()['createdAt'];
    if (existingAt is! Timestamp) {
      byTargetId[targetId] = doc;
      continue;
    }
    if (docAt is Timestamp && docAt.compareTo(existingAt) > 0) {
      byTargetId[targetId] = doc;
    }
  }

  return byTargetId.values.toList();
}

/// Other user IDs from match documents involving [currentUserId].
Set<String> matchedUserIdsFromMatches(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> matchDocs,
  String currentUserId,
) {
  final ids = <String>{};
  for (final doc in matchDocs) {
    final users = doc.data()['users'];
    if (users is! List) continue;
    for (final userId in users) {
      final id = userId.toString();
      if (id.isNotEmpty && id != currentUserId) {
        ids.add(id);
      }
    }
  }
  return ids;
}

/// Outgoing likes for the Sent tab, excluding anyone you already have a match with.
List<QueryDocumentSnapshot<Map<String, dynamic>>> likedYouOutgoingUnmatchedLikes(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> outgoingDocs,
  Set<String> matchedUserIds,
) {
  return likedYouOutgoingLikes(outgoingDocs).where((doc) {
    final targetId = doc.data()['toUserId']?.toString() ?? '';
    return targetId.isNotEmpty && !matchedUserIds.contains(targetId);
  }).toList();
}
