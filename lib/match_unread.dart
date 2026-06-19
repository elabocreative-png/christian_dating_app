import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user unread message counts stored on match documents as `unreadCountBy`.
/// Per-user chat open state is stored as `openedBy.{userId}`.
/// Per-user last-read time is stored as `lastReadAt.{userId}`.
abstract final class MatchUnread {
  static String countField(String userId) => 'unreadCountBy.$userId';

  static String openedField(String userId) => 'openedBy.$userId';

  static String lastReadField(String userId) => 'lastReadAt.$userId';

  static Future<void> incrementForRecipient({
    required DocumentReference<Map<String, dynamic>> matchRef,
    required String senderId,
    required List<String> userIds,
  }) async {
    final recipientId = userIds.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );
    if (recipientId.isEmpty) return;

    await matchRef.set(
      {countField(recipientId): FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  static Future<void> clearForUser({
    required DocumentReference<Map<String, dynamic>> matchRef,
    required String userId,
  }) async {
    await matchRef.set(
      {countField(userId): 0},
      SetOptions(merge: true),
    );
  }

  static Future<void> markOpenedForUser({
    required DocumentReference<Map<String, dynamic>> matchRef,
    required String userId,
  }) async {
    await matchRef.set(
      {openedField(userId): true},
      SetOptions(merge: true),
    );
  }

  /// Clears unread count and marks the chat read/opened for [userId].
  static Future<void> markChatOpened({
    required String matchId,
    required String userId,
  }) async {
    final matchRef =
        FirebaseFirestore.instance.collection('matches').doc(matchId);
    final now = Timestamp.now();
    final payload = <String, dynamic>{
      countField(userId): 0,
      openedField(userId): true,
      lastReadField(userId): now,
    };

    try {
      await matchRef.update(payload);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await matchRef.set(payload, SetOptions(merge: true));
    }
  }

  static bool isOpenedByUser(Map<String, dynamic> data, String userId) {
    final raw = data['openedBy'];
    if (raw is Map) {
      return raw[userId] == true;
    }
    return false;
  }

  static bool hasReadThroughLastMessage(
    Map<String, dynamic> data,
    String userId,
  ) {
    final lastMsg = data['lastMessageAt'];
    if (lastMsg is! Timestamp) return false;

    final lastReadRaw = data['lastReadAt'];
    if (lastReadRaw is! Map) return false;

    final readAt = lastReadRaw[userId];
    if (readAt is! Timestamp) return false;

    return !readAt.toDate().isBefore(lastMsg.toDate());
  }

  /// Match with no messages yet that this user has not opened in chat.
  static bool isUnopenedNewConnection(
    Map<String, dynamic> data,
    String userId,
  ) {
    if (data['lastMessageAt'] != null) return false;
    return !isOpenedByUser(data, userId);
  }

  static bool hasUnreadMessages(Map<String, dynamic> data, String userId) {
    if (data['lastMessageAt'] == null) return false;

    if (data['lastMessageSenderId']?.toString() == userId) return false;

    final unreadRaw = data['unreadCountBy'];
    if (unreadRaw is Map && unreadRaw.containsKey(userId)) {
      final value = unreadRaw[userId];
      if (value is num) return value > 0;
    }

    if (hasReadThroughLastMessage(data, userId)) return false;
    if (isOpenedByUser(data, userId)) return false;

    return true;
  }

  /// Red dot on a message-thread avatar (unopened / unread).
  static bool showsMessageUnreadDot(
    Map<String, dynamic> data,
    String userId, {
    bool openedLocally = false,
  }) {
    if (openedLocally) return false;
    return hasUnreadMessages(data, userId);
  }

  static bool isMessageThreadOpened(
    Map<String, dynamic> data,
    String userId, {
    bool openedLocally = false,
  }) {
    if (openedLocally) return true;
    if (isOpenedByUser(data, userId)) return true;
    if (hasReadThroughLastMessage(data, userId)) return true;
    return false;
  }

  /// Opened chat where the other person sent the last message (awaiting your reply).
  static bool isYourMoveThread(
    Map<String, dynamic> data,
    String userId, {
    bool openedLocally = false,
  }) {
    if (data['lastMessageAt'] == null) return false;
    if (showsMessageUnreadDot(data, userId, openedLocally: openedLocally)) {
      return false;
    }
    if (!isMessageThreadOpened(data, userId, openedLocally: openedLocally)) {
      return false;
    }
    final lastSender = data['lastMessageSenderId']?.toString();
    return lastSender != null &&
        lastSender.isNotEmpty &&
        lastSender != userId;
  }

  static bool showsUnreadIndicator(
    Map<String, dynamic> data,
    String userId,
  ) {
    return isUnopenedNewConnection(data, userId) ||
        hasUnreadMessages(data, userId);
  }

  static int countForUser(Map<String, dynamic> data, String userId) {
    return hasUnreadMessages(data, userId) ? 1 : 0;
  }

  static int totalUnreadForUser(
    Iterable<Map<String, dynamic>> matchDocs,
    String userId,
  ) {
    var total = 0;
    for (final data in matchDocs) {
      total += countForUser(data, userId);
    }
    return total;
  }

  /// Message threads with a red-dot indicator in the Messages list.
  static int unreadMessageThreadsCount(
    Iterable<Map<String, dynamic>> matchDocs,
    String userId,
  ) {
    var total = 0;
    for (final data in matchDocs) {
      if (data['lastMessageAt'] != null && hasUnreadMessages(data, userId)) {
        total += 1;
      }
    }
    return total;
  }

  /// Like [unreadMessageThreadsCount] but keyed by match document id.
  static int unreadMessageThreadsCountFromDocs(
    Iterable<({String id, Map<String, dynamic> data})> matchDocs,
    String userId, {
    Set<String> sessionReadMatchIds = const {},
  }) {
    var total = 0;
    for (final doc in matchDocs) {
      if (sessionReadMatchIds.contains(doc.id)) continue;
      final data = doc.data;
      if (data['lastMessageAt'] != null && hasUnreadMessages(data, userId)) {
        total += 1;
      }
    }
    return total;
  }

  /// New-connection avatars with a red-dot indicator (no messages yet, not opened).
  static int unopenedNewConnectionsCount(
    Iterable<Map<String, dynamic>> matchDocs,
    String userId,
  ) {
    var total = 0;
    for (final data in matchDocs) {
      if (isUnopenedNewConnection(data, userId)) {
        total += 1;
      }
    }
    return total;
  }

  /// Conversations with a red-dot indicator (unopened new match or unread messages).
  static int totalUnopenedChatsForUser(
    Iterable<Map<String, dynamic>> matchDocs,
    String userId,
  ) {
    var total = 0;
    for (final data in matchDocs) {
      if (showsUnreadIndicator(data, userId)) {
        total += 1;
      }
    }
    return total;
  }
}
