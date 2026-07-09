import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
  });

  Future<void> pumpAuthScreen(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
  }

  group('AuthScreen', () {
    testWidgets('renders login mode', (tester) async {
      await pumpAuthScreen(tester);

      expect(find.text('ChristMeets'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Confirm password'), findsNothing);
    });

    testWidgets('toggles to sign up mode', (tester) async {
      await pumpAuthScreen(tester);

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
      expect(
        find.text('I agree to the Terms of Service and Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar when login fields are empty', (tester) async {
      await pumpAuthScreen(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email and password'), findsOneWidget);
      verifyNever(() => mockAuth.login(any(), any()));
    });

    testWidgets('shows snackbar when sign up terms are not accepted',
        (tester) async {
      await pumpAuthScreen(tester);
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret12');
      await tester.enterText(find.byType(TextField).at(2), 'secret12');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(
        find.text('Please accept the Terms and Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('calls login when sign in is submitted', (tester) async {
      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => null);

      await pumpAuthScreen(tester);
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret12');
      await tester.tap(find.text('Sign in'));
      await tester.pump();

      verify(() => mockAuth.login('user@example.com', 'secret12')).called(1);
    });
  });
}
