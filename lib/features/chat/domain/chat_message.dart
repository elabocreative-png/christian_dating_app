/// A single chat message, expressed in app types (no cloud_firestore types).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.likedContent,
    this.createdAt,
    this.likedBy = const <String>[],
  });

  final String id;
  final String senderId;
  final String text;

  /// Optional "Liked: ..." reference content attached to the message.
  final String? likedContent;
  final DateTime? createdAt;
  final List<String> likedBy;

  bool isLikedBy(String userId) => likedBy.contains(userId);
}
