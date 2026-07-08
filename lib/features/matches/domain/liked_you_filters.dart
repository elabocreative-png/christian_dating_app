import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

/// A like document expressed in app types: its id and raw data map.
typedef LikeEntry = ({String id, Map<String, dynamic> data});

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
List<LikeEntry> likedYouVisibleIncomingLikes(List<LikeEntry> docs) {
  return docs.where((d) => !isLikedYouMessageIntro(d.data)).toList();
}

/// Incoming likes with a message for the Liked You **Intros** tab.
List<LikeEntry> likedYouIncomingIntros(List<LikeEntry> docs) {
  return docs.where((d) => isLikedYouMessageIntro(d.data)).toList();
}

/// One outgoing like per target user (newest [createdAt] wins).
List<LikeEntry> likedYouOutgoingLikes(List<LikeEntry> docs) {
  final byTargetId = <String, LikeEntry>{};

  for (final doc in docs) {
    final targetId = doc.data['toUserId']?.toString() ?? '';
    if (targetId.isEmpty) continue;

    final existing = byTargetId[targetId];
    if (existing == null) {
      byTargetId[targetId] = doc;
      continue;
    }

    final existingAt = firestoreDateTimeFrom(existing.data['createdAt']);
    final docAt = firestoreDateTimeFrom(doc.data['createdAt']);
    if (existingAt == null) {
      byTargetId[targetId] = doc;
      continue;
    }
    if (docAt != null && docAt.isAfter(existingAt)) {
      byTargetId[targetId] = doc;
    }
  }

  return byTargetId.values.toList();
}

/// Other user IDs from match documents involving [currentUserId].
Set<String> matchedUserIdsFromMatches(
  List<MatchEntry> matchDocs,
  String currentUserId,
) {
  final ids = <String>{};
  for (final doc in matchDocs) {
    final users = doc.data['users'];
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
List<LikeEntry> likedYouOutgoingUnmatchedLikes(
  List<LikeEntry> outgoingDocs,
  Set<String> matchedUserIds,
) {
  return likedYouOutgoingLikes(outgoingDocs).where((doc) {
    final targetId = doc.data['toUserId']?.toString() ?? '';
    return targetId.isNotEmpty && !matchedUserIds.contains(targetId);
  }).toList();
}
