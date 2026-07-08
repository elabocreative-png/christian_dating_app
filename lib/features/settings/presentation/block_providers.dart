import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/settings/data/block_repository.dart';
import 'package:christian_dating_app/features/settings/domain/blocked_user_record.dart';

/// Live blocked user ids for the given viewer.
final blockedUserIdsProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, uid) {
  return ref.watch(blockRepositoryProvider).watchBlockedUserIds(uid);
});

/// Live blocked user records for the settings list.
final blockedRecordsProvider =
    StreamProvider.autoDispose.family<List<BlockedUserRecord>, String>(
        (ref, uid) {
  return ref.watch(blockRepositoryProvider).watchBlockedRecords(uid);
});
