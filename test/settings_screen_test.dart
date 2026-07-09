import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/settings/presentation/settings_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
  });

  Future<void> pumpSettingsScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Login screen'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    testWidgets('renders settings items and logout button', (tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('Blocked Members'), findsOneWidget);
      expect(find.text('ChristMeets FAQ'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('logout confirms and calls auth repository', (tester) async {
      when(() => mockAuth.logout()).thenAnswer((_) async {});

      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log out'));
      await tester.pumpAndSettle();

      verify(() => mockAuth.logout()).called(1);
      expect(find.text('Login screen'), findsOneWidget);
    });
  });
}
