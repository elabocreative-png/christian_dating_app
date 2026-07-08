import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/services/match_read_state.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';
import 'package:christian_dating_app/features/matches/domain/match_unread.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';

/// Incoming-likes badge on the Liked You tab (excludes message intros, which are
/// delivered to Chats instead). Shares the same likes stream as the chats list.
final likedYouCountProvider =
    Provider.autoDispose.family<int, String>((ref, uid) {
  final likes = ref.watch(incomingLikesProvider(uid)).asData?.value ??
      const <LikeEntry>[];
  return likes.where((entry) => !isLikedYouMessageIntro(entry.data)).length;
});

/// Message threads with an unread indicator (excludes session reads). Shares the
/// same matches stream as the chats list.
final unreadMessageThreadsProvider =
    Provider.autoDispose.family<int, String>((ref, uid) {
  final matches = ref.watch(matchesStreamProvider(uid)).asData?.value ??
      const <MatchEntry>[];
  final sessionRead = ref.watch(matchReadStateProvider);
  return MatchUnread.unreadMessageThreadsCountFromDocs(
    matches,
    uid,
    sessionReadMatchIds: sessionRead,
  );
});
