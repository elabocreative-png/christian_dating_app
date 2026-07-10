import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/chat/domain/chat_context.dart';
import 'package:christian_dating_app/features/chat/domain/chat_message.dart';
import 'package:christian_dating_app/features/chat/presentation/chat_providers.dart';
import 'package:christian_dating_app/features/chat/presentation/chat_screen.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockChat;

  const uid = 'user-1';
  const matchId = 'match-1';
  const contextKey = '$matchId|$uid';

  setUp(() {
    mockChat = MockChatRepository();
    when(
      () => mockChat.markChatOpened(matchId: matchId, userId: uid),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpChatScreen(
    WidgetTester tester, {
    AsyncValue<List<ChatMessage>>? messagesState,
    AsyncValue<ChatContext>? contextState,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          chatRepositoryProvider.overrideWithValue(mockChat),
          chatMessagesProvider(matchId).overrideWithValue(
            messagesState ?? const AsyncData([]),
          ),
          chatContextProvider(contextKey).overrideWithValue(
            contextState ??
                AsyncData(
                  ChatContext(
                    otherUser: const {'name': 'Sam', 'age': 27},
                    matchCreatedAt: DateTime(2026, 7, 9, 12),
                  ),
                ),
          ),
        ],
        child: const MaterialApp(home: ChatScreen(matchId: matchId)),
      ),
    );
  }

  group('ChatScreen empty state', () {
    testWidgets('shows match hero and composer when there are no messages',
        (tester) async {
      await pumpChatScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Sam'), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
      expect(find.text('Type a message'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      verify(
        () => mockChat.markChatOpened(matchId: matchId, userId: uid),
      ).called(1);
    });

    testWidgets('sends a message from the composer', (tester) async {
      when(
        () => mockChat.sendMessage(
          matchId: matchId,
          senderId: uid,
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async {});

      await pumpChatScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello Sam');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      verify(
        () => mockChat.sendMessage(
          matchId: matchId,
          senderId: uid,
          text: 'Hello Sam',
        ),
      ).called(1);
    });
  });
}
