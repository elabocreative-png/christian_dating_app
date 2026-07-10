import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';
import 'package:christian_dating_app/features/matches/presentation/match_list_screen.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';
import 'package:christian_dating_app/features/profile/presentation/profile_providers.dart';
import 'package:christian_dating_app/features/settings/presentation/block_providers.dart';

void main() {
  const uid = 'user-1';

  Future<void> pumpMatchListScreen(
    WidgetTester tester, {
    required AsyncValue<List<MatchEntry>> matchesState,
    AsyncValue<Map<String, Map<String, dynamic>>>? profilesState,
    String profilesCacheKey = 'user-2',
  }) {
    final overrides = [
      currentUserIdProvider.overrideWithValue(uid),
      matchesStreamProvider(uid).overrideWithValue(matchesState),
      incomingLikesProvider(uid).overrideWithValue(const AsyncData([])),
      blockedUserIdsProvider(uid).overrideWithValue(const AsyncData({})),
    ];

    if (profilesState != null) {
      overrides.add(
        profilesByIdsProvider(profilesCacheKey).overrideWithValue(profilesState),
      );
    }

    return tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: MatchListScreen()),
      ),
    );
  }

  group('MatchListScreen empty state', () {
    testWidgets('shows no connections copy when there are no matches',
        (tester) async {
      await pumpMatchListScreen(tester, matchesState: const AsyncData([]));
      await tester.pumpAndSettle();

      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('No new connections or messages.'), findsOneWidget);
      expect(
        find.text('Chats appear here once a conversation from match starts.'),
        findsOneWidget,
      );
      expect(find.text('Messages'), findsNothing);
    });

    testWidgets('shows no messages copy when matches have no conversation yet',
        (tester) async {
      const otherUserId = 'user-2';
      final matchEntry = (
        id: 'match-1',
        data: <String, dynamic>{
          'users': [uid, otherUserId],
          'createdAt': DateTime(2026, 6, 1),
        },
      );

      await pumpMatchListScreen(
        tester,
        matchesState: AsyncData([matchEntry]),
        profilesState: AsyncData({
          otherUserId: {'name': 'Sam'},
        }),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Connections'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Open a match above and send a message'), findsOneWidget);
    });
  });
}
