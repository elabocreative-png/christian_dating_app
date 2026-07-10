import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/matches/presentation/liked_you_screen.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';
import 'package:christian_dating_app/features/settings/presentation/block_providers.dart';

void main() {
  const uid = 'user-1';

  Future<void> pumpLikedYouScreen(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          incomingLikesProvider(uid).overrideWithValue(const AsyncData([])),
          outgoingLikesProvider(uid).overrideWithValue(const AsyncData([])),
          matchesStreamProvider(uid).overrideWithValue(const AsyncData([])),
          blockedUserIdsProvider(uid).overrideWithValue(const AsyncData({})),
        ],
        child: const MaterialApp(home: LikedYouScreen()),
      ),
    );
  }

  group('LikedYouScreen empty state', () {
    testWidgets('shows likes tab empty copy by default', (tester) async {
      await pumpLikedYouScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('No likes yet'), findsOneWidget);
      expect(
        find.text('Likes will appear here as soon as you get them.'),
        findsOneWidget,
      );
    });

    testWidgets('shows intros tab empty copy', (tester) async {
      await pumpLikedYouScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Intros 0'));
      await tester.pumpAndSettle();

      expect(find.text('No intros yet'), findsOneWidget);
      expect(
        find.text('Profile messages and comments will show up here.'),
        findsOneWidget,
      );
    });

    testWidgets('shows sent tab empty copy', (tester) async {
      await pumpLikedYouScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sent 0'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing sent yet'), findsOneWidget);
      expect(
        find.text('Profiles you like on Discover will appear here.'),
        findsOneWidget,
      );
    });
  });
}
