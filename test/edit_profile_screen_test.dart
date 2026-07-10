import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/features/profile/presentation/edit_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfile;

  const uid = 'user-1';

  const incompleteProfile = {
    'name': 'Alex',
    'age': 28,
    'lookingFor': 'Friendship',
    'gender': 'Man',
  };

  const completeProfile = {
    'name': 'Alex',
    'age': 28,
    'city': 'Austin',
    'denomination': 'Baptist',
    'lookingFor': 'Friendship',
    'gender': 'Man',
    'photos': ['https://example.com/1.jpg'],
    'prompts': [
      {'question': 'Faith?', 'answer': 'Yes'},
    ],
  };

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockProfile = MockProfileRepository();
    when(() => mockProfile.fetchOrEnsureProfile(uid))
        .thenAnswer((_) async => Map<String, dynamic>.from(incompleteProfile));
    when(() => mockProfile.updateProfile(any(), any()))
        .thenAnswer((_) async {});
  });

  Future<GoRouter> pumpEditProfileScreen(
    WidgetTester tester, {
    Map<String, dynamic>? profile,
  }) async {
    if (profile != null) {
      when(() => mockProfile.fetchOrEnsureProfile(uid))
          .thenAnswer((_) async => Map<String, dynamic>.from(profile));
    }

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Parent screen'))),
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.push(AppRoutes.profileEdit);
    await tester.pumpAndSettle();
    return router;
  }

  group('EditProfileScreen', () {
    testWidgets('loads profile and renders edit sections', (tester) async {
      await pumpEditProfileScreen(tester);

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Profile strength'), findsOneWidget);
    });

    testWidgets('hides profile strength when profile is complete', (tester) async {
      await pumpEditProfileScreen(tester, profile: completeProfile);

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Profile strength'), findsNothing);
    });

    testWidgets('saves profile and pops on back', (tester) async {
      await pumpEditProfileScreen(tester);

      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      verify(() => mockProfile.updateProfile(uid, any())).called(1);
      expect(find.text('Parent screen'), findsOneWidget);
    });
  });
}
