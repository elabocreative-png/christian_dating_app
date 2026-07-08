import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/chat/domain/chat_context.dart';
import 'package:christian_dating_app/features/chat/domain/chat_message.dart';
import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';

/// All chat-related Firestore access. Returns app types (domain models / maps)
/// so the presentation layer never touches cloud_firestore directly.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _matchRef(String matchId) =>
      _firestore.collection('matches').doc(matchId);

  CollectionReference<Map<String, dynamic>> _messagesRef(String matchId) =>
      _matchRef(matchId).collection('messages');

  String _countField(String userId) => 'unreadCountBy.$userId';

  String _openedField(String userId) => 'openedBy.$userId';

  String _lastReadField(String userId) => 'lastReadAt.$userId';

  Future<void> _incrementUnreadForRecipient({
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
      {_countField(recipientId): FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  /// Clears unread count and marks the chat read/opened for [userId].
  Future<void> markChatOpened({
    required String matchId,
    required String userId,
  }) async {
    final matchRef = _matchRef(matchId);
    final payload = <String, dynamic>{
      _countField(userId): 0,
      _openedField(userId): true,
      _lastReadField(userId): Timestamp.now(),
    };

    try {
      await matchRef.update(payload);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await matchRef.set(payload, SetOptions(merge: true));
    }
  }

  /// Live, chronologically-ordered messages for a match.
  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return _messagesRef(matchId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_messageFromDoc).toList());
  }

  ChatMessage _messageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final likedBy = data['likedBy'];
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      likedContent: data['content']?.toString(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      likedBy: likedBy is List
          ? likedBy.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }

  Future<void> toggleMessageLike({
    required String matchId,
    required String messageId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    await _messagesRef(matchId).doc(messageId).update({
      'likedBy': currentlyLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    String? likedContent,
  }) async {
    await _messagesRef(matchId).add({
      'senderId': senderId,
      'text': text,
      'content': ?likedContent,
      'createdAt': Timestamp.now(),
    });

    final matchRef = _matchRef(matchId);
    await matchRef.set(
      {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      },
      SetOptions(merge: true),
    );

    final matchSnap = await matchRef.get();
    final users = matchSnap.data()?['users'];
    if (users is List) {
      await _incrementUnreadForRecipient(
        matchRef: matchRef,
        senderId: senderId,
        userIds: List<String>.from(users),
      );
    }
  }

  /// Loads the other participant's profile and the match creation time.
  Future<ChatContext> loadChatContext({
    required String matchId,
    required String currentUserId,
  }) async {
    final matchDoc = await _matchRef(matchId).get();

    DateTime? matchCreatedAt;
    final createdAt = matchDoc.data()?['createdAt'];
    matchCreatedAt = firestoreDateTimeFrom(createdAt);

    final matchData = matchDoc.data();
    if (!matchDoc.exists || matchData == null || matchData['users'] == null) {
      return ChatContext(matchCreatedAt: matchCreatedAt);
    }

    final users = List<String>.from(matchData['users']);
    final otherUserId = users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) {
      return ChatContext(matchCreatedAt: matchCreatedAt);
    }

    final userDoc =
        await _firestore.collection('users').doc(otherUserId).get();
    final data = userDoc.data();
    if (data == null) {
      return ChatContext(matchCreatedAt: matchCreatedAt);
    }
    return ChatContext(
      otherUser: {...data, 'uid': otherUserId},
      matchCreatedAt: matchCreatedAt,
    );
  }

  /// Deletes all messages and the match document (unmatch).
  Future<void> unmatch(String matchId) async {
    final matchRef = _matchRef(matchId);
    final messages = await matchRef.collection('messages').get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(matchRef);
    await batch.commit();
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});
