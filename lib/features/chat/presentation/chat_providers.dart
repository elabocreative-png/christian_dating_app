import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/chat/domain/chat_context.dart';
import 'package:christian_dating_app/features/chat/domain/chat_message.dart';

/// Cache key for [chatContextProvider].
String chatContextCacheKey({required String matchId, required String uid}) =>
    '$matchId|$uid';

/// Match metadata and the other participant's profile for a chat thread.
final chatContextProvider = FutureProvider.autoDispose
    .family<ChatContext, String>((ref, cacheKey) async {
  final sep = cacheKey.indexOf('|');
  if (sep <= 0 || sep >= cacheKey.length - 1) {
    throw StateError('Invalid chat context key');
  }
  final matchId = cacheKey.substring(0, sep);
  final uid = cacheKey.substring(sep + 1);
  return ref.read(chatRepositoryProvider).loadChatContext(
        matchId: matchId,
        currentUserId: uid,
      );
});

/// Live messages for a given match id.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(chatRepositoryProvider).watchMessages(matchId);
});
