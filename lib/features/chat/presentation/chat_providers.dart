import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/chat/domain/chat_message.dart';

/// Live messages for a given match id.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(chatRepositoryProvider).watchMessages(matchId);
});
