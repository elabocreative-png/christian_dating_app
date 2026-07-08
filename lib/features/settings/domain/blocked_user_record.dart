import 'package:christian_dating_app/core/models/block_source.dart';

class BlockedUserRecord {
  const BlockedUserRecord({
    required this.blockedUserId,
    required this.source,
    required this.blockedAt,
  });

  final String blockedUserId;
  final BlockSource source;
  final DateTime blockedAt;
}
