import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';

/// Pure unread/open-state logic for match documents.
///
/// Firestore writes live in [ChatRepository].
abstract final class MatchUnread {
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
    final lastMsgAt = firestoreDateTimeFrom(data['lastMessageAt']);
    if (lastMsgAt == null) return false;

    final lastReadRaw = data['lastReadAt'];
    if (lastReadRaw is! Map) return false;

    final readAt = firestoreDateTimeFrom(lastReadRaw[userId]);
    if (readAt == null) return false;

    return !readAt.isBefore(lastMsgAt);
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
