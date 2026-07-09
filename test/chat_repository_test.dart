import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/chat/data/chat_repository.dart';

void main() {
  group('ChatRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepository repo;
    const matchId = 'user-a_user-b';

    Map<String, dynamic>? unreadBy(Map<String, dynamic>? data) {
      final raw = data?['unreadCountBy'];
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    }

    Map<String, dynamic>? openedBy(Map<String, dynamic>? data) {
      final raw = data?['openedBy'];
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repo = ChatRepository(firestore: firestore);
      await firestore.collection('matches').doc(matchId).set({
        'users': ['user-a', 'user-b'],
      });
    });

    test('sendMessage writes message and updates match metadata', () async {
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-a',
        text: 'Hello there',
        likedContent: 'Profile photo',
      );

      final messages = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(messages.docs, hasLength(1));
      expect(messages.docs.single.data()['text'], 'Hello there');
      expect(messages.docs.single.data()['content'], 'Profile photo');

      final match = await firestore.collection('matches').doc(matchId).get();
      expect(match.data()?['lastMessage'], 'Hello there');
      expect(match.data()?['lastMessageSenderId'], 'user-a');
      expect(unreadBy(match.data())?['user-b'], 1);
    });

    test('watchMessages emits ordered chat messages', () async {
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-a',
        text: 'First',
      );
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-b',
        text: 'Second',
      );

      final messages = await repo.watchMessages(matchId).first;
      expect(messages, hasLength(2));
      expect(messages.first.text, 'First');
      expect(messages.last.text, 'Second');
    });

    test('markChatOpened clears unread count for user', () async {
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-a',
        text: 'Ping',
      );

      await repo.markChatOpened(matchId: matchId, userId: 'user-b');

      final match = await firestore.collection('matches').doc(matchId).get();
      expect(unreadBy(match.data())?['user-b'], 0);
      expect(openedBy(match.data())?['user-b'], isTrue);
    });

    test('toggleMessageLike updates likedBy array', () async {
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-a',
        text: 'Like this',
      );
      final messageId = (await firestore
              .collection('matches')
              .doc(matchId)
              .collection('messages')
              .get())
          .docs
          .single
          .id;

      await repo.toggleMessageLike(
        matchId: matchId,
        messageId: messageId,
        userId: 'user-b',
        currentlyLiked: false,
      );

      var doc = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .get();
      expect(doc.data()?['likedBy'], ['user-b']);

      await repo.toggleMessageLike(
        matchId: matchId,
        messageId: messageId,
        userId: 'user-b',
        currentlyLiked: true,
      );

      doc = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .get();
      expect(doc.data()?['likedBy'], isEmpty);
    });

    test('unmatch deletes match and messages', () async {
      await repo.sendMessage(
        matchId: matchId,
        senderId: 'user-a',
        text: 'Bye',
      );

      await repo.unmatch(matchId);

      expect(
        (await firestore.collection('matches').doc(matchId).get()).exists,
        isFalse,
      );
      expect(
        (await firestore
                .collection('matches')
                .doc(matchId)
                .collection('messages')
                .get())
            .docs,
        isEmpty,
      );
    });

    test('loadChatContext returns other user profile', () async {
      await firestore.collection('users').doc('user-b').set({
        'name': 'Jordan',
        'age': 27,
      });

      final context = await repo.loadChatContext(
        matchId: matchId,
        currentUserId: 'user-a',
      );

      expect(context.otherUser?['name'], 'Jordan');
      expect(context.otherUser?['uid'], 'user-b');
    });
  });
}
