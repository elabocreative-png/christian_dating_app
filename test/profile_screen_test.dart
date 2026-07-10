import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/profile/presentation/profile_providers.dart';
import 'package:christian_dating_app/features/profile/presentation/profile_screen.dart';

void main() {
  const uid = 'user-1';

  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    required Map<String, dynamic> profile,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          myProfileProvider.overrideWithValue(AsyncData(profile)),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renders header, tabs, and complete-profile pill when incomplete',
        (tester) async {
      await pumpProfileScreen(
        tester,
        profile: const {'name': 'Alex', 'age': 28},
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.textContaining('Alex'), findsWidgets);
      expect(find.text('Complete profile'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('Get ExtraPlus (from K89 ZMW)'), findsOneWidget);
    });

    testWidgets('shows edit profile pill when profile is complete', (tester) async {
      await pumpProfileScreen(
        tester,
        profile: {
          'name': 'Alex',
          'age': 28,
          'city': 'Austin',
          'denomination': 'Baptist',
          'photos': ['https://example.com/1.jpg'],
          'prompts': [
            {'question': 'Faith?', 'answer': 'Yes'},
          ],
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Complete profile'), findsNothing);
    });
  });
}
