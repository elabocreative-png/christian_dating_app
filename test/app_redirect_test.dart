import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/core/navigation/app_router.dart';
import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/features/auth/domain/pending_signup.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockUser user;

  setUp(() {
    user = MockUser();
    when(() => user.uid).thenReturn('uid-1');
  });

  group('appRedirectForState', () {
    test('pending signup forces onboarding', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(
            email: 'a@b.com',
            password: 'secret',
          ),
          auth: const AsyncData(null),
          profileComplete: null,
          location: AppRoutes.home,
        ),
        AppRoutes.onboarding,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(
            email: 'a@b.com',
            password: 'secret',
          ),
          auth: const AsyncData(null),
          profileComplete: null,
          location: AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('auth loading forces loading route', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: const AsyncLoading(),
          profileComplete: null,
          location: AppRoutes.home,
        ),
        AppRoutes.loading,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: const AsyncLoading(),
          profileComplete: null,
          location: AppRoutes.loading,
        ),
        isNull,
      );
    });

    test('signed out forces login', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: const AsyncData(null),
          profileComplete: null,
          location: AppRoutes.home,
        ),
        AppRoutes.login,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: const AsyncData(null),
          profileComplete: null,
          location: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('profile loading keeps loading route', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: null,
          location: AppRoutes.home,
        ),
        AppRoutes.loading,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: null,
          location: AppRoutes.loading,
        ),
        isNull,
      );
    });

    test('incomplete profile forces onboarding', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: false,
          location: AppRoutes.home,
        ),
        AppRoutes.onboarding,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: false,
          location: AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('complete profile on gate routes redirects to discover tab', () {
      const complete = true;
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: AppRoutes.login,
        ),
        AppRoutes.homeDiscover,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: AppRoutes.onboarding,
        ),
        AppRoutes.homeDiscover,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: AppRoutes.loading,
        ),
        AppRoutes.homeDiscover,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: '/',
        ),
        AppRoutes.homeDiscover,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: AppRoutes.home,
        ),
        AppRoutes.homeDiscover,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: complete,
          location: AppRoutes.homeDiscover,
        ),
        isNull,
      );
    });

    test('complete profile allows deep routes', () {
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: true,
          location: AppRoutes.chat('match-1'),
        ),
        isNull,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: true,
          location: AppRoutes.settings,
        ),
        isNull,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: true,
          location: AppRoutes.profileEdit,
        ),
        isNull,
      );
      expect(
        appRedirectForState(
          pending: const PendingSignupState(),
          auth: AsyncData(user),
          profileComplete: true,
          location: AppRoutes.homeLikedYou,
        ),
        isNull,
      );
    });
  });
}
