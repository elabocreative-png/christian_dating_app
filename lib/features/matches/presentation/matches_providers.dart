import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

/// Live matches for the given user id.
final matchesStreamProvider =
    StreamProvider.autoDispose.family<List<MatchEntry>, String>((ref, uid) {
  return ref.watch(matchesRepositoryProvider).watchMatches(uid);
});

/// Live incoming likes addressed to the given user id.
final incomingLikesProvider =
    StreamProvider.autoDispose.family<List<LikeEntry>, String>((ref, uid) {
  return ref.watch(matchesRepositoryProvider).watchIncomingLikes(uid);
});

/// Live outgoing likes sent by the given user id.
final outgoingLikesProvider =
    StreamProvider.autoDispose.family<List<LikeEntry>, String>((ref, uid) {
  return ref.watch(matchesRepositoryProvider).watchOutgoingLikes(uid);
});
