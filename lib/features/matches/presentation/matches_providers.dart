import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

/// Live matches for the given user id.
final matchesStreamProvider =
    StreamProvider.autoDispose.family<List<MatchEntry>, String>((ref, uid) {
  return ref.watch(matchesRepositoryProvider).watchMatches(uid);
});

/// Live incoming likes (raw data maps) for the given user id.
final incomingLikesProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, uid) {
  return ref.watch(matchesRepositoryProvider).watchIncomingLikes(uid);
});
