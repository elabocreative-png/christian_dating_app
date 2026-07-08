/// Header context for a chat: the other participant's profile and when the
/// match was created. Expressed in app types (no cloud_firestore types).
class ChatContext {
  const ChatContext({this.otherUser, this.matchCreatedAt});

  final Map<String, dynamic>? otherUser;
  final DateTime? matchCreatedAt;
}
