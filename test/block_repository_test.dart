import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/settings/data/block_repository.dart';

void main() {
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
}
