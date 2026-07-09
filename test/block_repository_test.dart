import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/settings/data/block_repository.dart';

void main() {
  group('BlockRepository guards', () {
    late BlockRepository repo;

    setUp(() {
      repo = BlockRepository();
    });

    group('blockUser', () {
      test('returns false when blockedUserId is empty', () async {
        expect(
          await repo.blockUser(
            uid: 'uid-1',
            blockedUserId: '',
            source: BlockSource.discovery,
          ),
          isFalse,
        );
      });

      test('returns false when blocking self', () async {
        expect(
          await repo.blockUser(
            uid: 'uid-1',
            blockedUserId: 'uid-1',
            source: BlockSource.discovery,
          ),
          isFalse,
        );
      });
    });

    group('unblockUser', () {
      test('returns false when blockedUserId is empty', () async {
        expect(
          await repo.unblockUser(uid: 'uid-1', blockedUserId: ''),
          isFalse,
        );
      });
    });
  });

  group('BlockRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late BlockRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = BlockRepository(firestore: firestore);
    });

    test('blockUser persists blocked record and fetch returns ids', () async {
      final ok = await repo.blockUser(
        uid: 'viewer-1',
        blockedUserId: 'user-2',
        source: BlockSource.messages,
      );
      expect(ok, isTrue);

      expect(await repo.fetchBlockedUserIds('viewer-1'), {'user-2'});

      final doc = await firestore
          .collection('users')
          .doc('viewer-1')
          .collection('blocked')
          .doc('user-2')
          .get();
      expect(doc.data()?['source'], 'messages');
    });

    test('watchBlockedRecords maps source and user id', () async {
      await repo.blockUser(
        uid: 'viewer-1',
        blockedUserId: 'user-3',
        source: BlockSource.likedYou,
      );

      final records = await repo.watchBlockedRecords('viewer-1').first;
      expect(records, hasLength(1));
      expect(records.first.blockedUserId, 'user-3');
      expect(records.first.source, BlockSource.likedYou);
    });

    test('watchBlockedUserIds emits blocked user ids', () async {
      await repo.blockUser(
        uid: 'viewer-1',
        blockedUserId: 'user-4',
        source: BlockSource.discovery,
      );

      final ids = await repo.watchBlockedUserIds('viewer-1').first;
      expect(ids, {'user-4'});
    });

    test('unblockUser removes blocked record', () async {
      await repo.blockUser(
        uid: 'viewer-1',
        blockedUserId: 'user-5',
        source: BlockSource.matches,
      );

      expect(await repo.unblockUser(uid: 'viewer-1', blockedUserId: 'user-5'), isTrue);
      expect(await repo.fetchBlockedUserIds('viewer-1'), isEmpty);
    });

    test('defaults unknown source to discovery in watchBlockedRecords', () async {
      await firestore
          .collection('users')
          .doc('viewer-1')
          .collection('blocked')
          .doc('legacy-user')
          .set({
        'blockedUserId': 'legacy-user',
        'source': 'unknown_source',
        'blockedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final records = await repo.watchBlockedRecords('viewer-1').first;
      expect(records.single.blockedUserId, 'legacy-user');
      expect(records.single.source, BlockSource.discovery);
    });
  });
}
