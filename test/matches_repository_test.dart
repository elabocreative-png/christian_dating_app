import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/features/matches/domain/match_id.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

void main() {
  group('MatchesRepository guards', () {
    late MatchesRepository repo;

    setUp(() {
      repo = MatchesRepository(firestore: FakeFirebaseFirestore());
    });

    test('dismissConnection returns false for empty ids', () async {
      expect(
        await repo.dismissConnection(
          uid: 'user-a',
          matchId: '',
          otherUserId: 'user-b',
        ),
        isFalse,
      );
    });

    test('revokeOutgoingLikes returns false for empty target', () async {
      expect(
        await repo.revokeOutgoingLikes(uid: 'user-a', targetUserId: ''),
        isFalse,
      );
    });

    test('sendDirectMessage returns null for blank message', () async {
      expect(
        await repo.sendDirectMessage(
          fromUserId: 'user-a',
          targetUserId: 'user-b',
          message: '   ',
        ),
        isNull,
      );
    });
  });

  group('MatchesRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late MatchesRepository repo;
    const userA = 'user-a';
    const userB = 'user-b';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = MatchesRepository(
        firestore: firestore,
        chatRepository: ChatRepository(firestore: firestore),
        profileRepository: ProfileRepository(firestore: firestore),
      );
    });

    Future<void> seedProfile(String uid) {
      return firestore.collection('users').doc(uid).set({
        'discoveryMode': kDiscoveryModeDating,
      });
    }

    test('sendLike writes outgoing like without creating match', () async {
      await seedProfile(userA);

      final result = await repo.sendLike(
        fromUserId: userA,
        targetUserId: userB,
        type: 'profile',
        content: 'Photo 1',
        answer: '',
        message: '',
        discoveryMode: kDiscoveryModeDating,
      );

      expect(result.liked, isTrue);
      expect(result.isNewMatch, isFalse);

      final likes = await firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: userA)
          .get();
      expect(likes.docs, hasLength(1));
      expect(
        (await firestore.collection('matches').get()).docs,
        isEmpty,
      );
    });

    test('sendLike with message creates match thread and chat message', () async {
      await seedProfile(userA);
      final matchId = matchIdForUsers(userA, userB);

      final result = await repo.sendLike(
        fromUserId: userA,
        targetUserId: userB,
        type: 'profile',
        content: 'Photo 1',
        answer: '',
        message: 'Nice profile',
        discoveryMode: kDiscoveryModeDating,
      );

      expect(result.liked, isTrue);
      expect(result.isNewMatch, isFalse);

      final match = await firestore.collection('matches').doc(matchId).get();
      expect(match.exists, isTrue);

      final messages = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(messages.docs.single.data()['text'], 'Nice profile');
    });

    test('sendLike returns alreadyLiked for duplicate content', () async {
      await seedProfile(userA);

      const args = (
        fromUserId: userA,
        targetUserId: userB,
        type: 'profile',
        content: 'Photo 1',
        answer: '',
        message: '',
        discoveryMode: kDiscoveryModeDating,
      );

      expect(
        (await repo.sendLike(
          fromUserId: args.fromUserId,
          targetUserId: args.targetUserId,
          type: args.type,
          content: args.content,
          answer: args.answer,
          message: args.message,
          discoveryMode: args.discoveryMode,
        )).liked,
        isTrue,
      );

      final duplicate = await repo.sendLike(
        fromUserId: args.fromUserId,
        targetUserId: args.targetUserId,
        type: args.type,
        content: args.content,
        answer: args.answer,
        message: args.message,
        discoveryMode: args.discoveryMode,
      );
      expect(duplicate.liked, isFalse);
      expect(duplicate.alreadyLiked, isTrue);
    });

    test('sendLike creates new match when reverse like exists', () async {
      await seedProfile(userA);
      await firestore.collection('likes').add({
        'fromUserId': userB,
        'toUserId': userA,
        'type': 'profile',
        'content': 'Photo 2',
        'answer': '',
        'message': '',
        'discoveryMode': kDiscoveryModeDating,
        'createdAt': Timestamp.now(),
      });

      final matchId = matchIdForUsers(userA, userB);
      final result = await repo.sendLike(
        fromUserId: userA,
        targetUserId: userB,
        type: 'profile',
        content: 'Photo 1',
        answer: '',
        message: '',
        discoveryMode: kDiscoveryModeDating,
      );

      expect(result.liked, isTrue);
      expect(result.isNewMatch, isTrue);
      expect(result.matchId, matchId);

      final match = await firestore.collection('matches').doc(matchId).get();
      expect(match.data()?['mutualMatch'], isTrue);
      expect(match.data()?['matchedBy'], userA);
    });

    test('deleteLike removes like document', () async {
      final doc = await firestore.collection('likes').add({
        'fromUserId': userA,
        'toUserId': userB,
        'content': 'Photo 1',
      });

      await repo.deleteLike(doc.id);

      expect((await firestore.collection('likes').get()).docs, isEmpty);
    });

    test('watchIncomingLikes and watchOutgoingLikes filter by user', () async {
      await firestore.collection('likes').add({
        'fromUserId': userB,
        'toUserId': userA,
        'content': 'incoming',
      });
      await firestore.collection('likes').add({
        'fromUserId': userA,
        'toUserId': userB,
        'content': 'outgoing',
      });

      final incoming = await repo.watchIncomingLikes(userA).first;
      final outgoing = await repo.watchOutgoingLikes(userA).first;

      expect(incoming, hasLength(1));
      expect(incoming.single.data['content'], 'incoming');
      expect(outgoing, hasLength(1));
      expect(outgoing.single.data['content'], 'outgoing');
    });

    test('revokeOutgoingLikes deletes outgoing likes to target', () async {
      await firestore.collection('likes').add({
        'fromUserId': userA,
        'toUserId': userB,
        'content': 'one',
      });
      await firestore.collection('likes').add({
        'fromUserId': userA,
        'toUserId': userB,
        'content': 'two',
      });

      expect(
        await repo.revokeOutgoingLikes(uid: userA, targetUserId: userB),
        isTrue,
      );
      expect((await firestore.collection('likes').get()).docs, isEmpty);
    });

    test('sendDirectMessage creates match and first message', () async {
      final matchId = matchIdForUsers(userA, userB);

      final returnedId = await repo.sendDirectMessage(
        fromUserId: userA,
        targetUserId: userB,
        message: 'Hey!',
      );

      expect(returnedId, matchId);
      final messages = await firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(messages.docs.single.data()['text'], 'Hey!');
    });

    test('dismissConnection unmatches and clears outgoing likes', () async {
      await seedProfile(userA);
      final matchId = matchIdForUsers(userA, userB);

      await repo.sendLike(
        fromUserId: userA,
        targetUserId: userB,
        type: 'profile',
        content: 'Photo 1',
        answer: '',
        message: 'Hello',
        discoveryMode: kDiscoveryModeDating,
      );

      expect(
        await repo.dismissConnection(
          uid: userA,
          matchId: matchId,
          otherUserId: userB,
        ),
        isTrue,
      );

      expect(
        (await firestore.collection('matches').doc(matchId).get()).exists,
        isFalse,
      );
      expect((await firestore.collection('likes').get()).docs, isEmpty);
    });
  });
}
