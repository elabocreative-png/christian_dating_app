import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_navigator.dart';
import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/features/auth/domain/pending_signup.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_screen.dart';
import 'package:christian_dating_app/features/chat/presentation/chat_screen.dart';
import 'package:christian_dating_app/features/onboarding/presentation/profile_setup_screen.dart';
import 'package:christian_dating_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:christian_dating_app/features/settings/domain/faq_content.dart';
import 'package:christian_dating_app/features/settings/presentation/blocked_users_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/deactivate_account_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/faq_detail_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/faq_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/help_support_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/privacy_policy_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/report_issue_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/settings_screen.dart';
import 'package:christian_dating_app/features/settings/presentation/terms_and_conditions_screen.dart';
import 'package:christian_dating_app/main_navigation.dart';

/// Notifies [GoRouter] when auth, pending signup, or profile completion changes.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    _ref = ref;
    _ref.listen(pendingSignupProvider, _notify);
    _ref.listen(authStateProvider, _onAuthChanged, fireImmediately: true);
  }

  late final Ref _ref;
  ProviderSubscription<bool?>? _profileSub;

  void _notify(Object? previous, Object? next) => notifyListeners();

  void _onAuthChanged(
    AsyncValue<User?>? _,
    AsyncValue<User?> next,
  ) {
    _profileSub?.close();
    _profileSub = null;
    notifyListeners();

    final uid = next.asData?.value?.uid;
    if (uid != null) {
      _profileSub = _ref.listen(profileCompleteProvider(uid), _notify);
    }
  }

  @override
  void dispose() {
    _profileSub?.close();
    super.dispose();
  }
}

String? appRedirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  final pending = ref.read(pendingSignupProvider);

  if (pending.isActive) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  final auth = ref.read(authStateProvider);
  if (auth.isLoading) {
    return location == AppRoutes.loading ? null : AppRoutes.loading;
  }

  final user = auth.value;
  if (user == null) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }

  final profileComplete = ref.read(profileCompleteProvider(user.uid));
  if (profileComplete == null) {
    return location == AppRoutes.loading ? null : AppRoutes.loading;
  }

  if (!profileComplete) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  if (location == AppRoutes.login ||
      location == AppRoutes.onboarding ||
      location == AppRoutes.loading ||
      location == '/') {
    return AppRoutes.home;
  }

  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: refresh,
    navigatorKey: rootNavigatorKey,
    observers: [matchPopupNavigatorObserver],
    redirect: (context, state) => appRedirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => MainNavigation(key: mainNavigationKey),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: 'report',
            builder: (context, state) => const ReportIssueScreen(),
          ),
          GoRoute(
            path: 'blocked',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          GoRoute(
            path: 'deactivate',
            builder: (context, state) => const DeactivateAccountScreen(),
          ),
          GoRoute(
            path: 'terms',
            builder: (context, state) => const TermsAndConditionsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: 'faq',
            builder: (context, state) => const FaqScreen(),
            routes: [
              GoRoute(
                path: ':index',
                builder: (context, state) {
                  final index =
                      int.tryParse(state.pathParameters['index'] ?? '');
                  if (index == null ||
                      index < 0 ||
                      index >= ChristMeetsFaq.items.length) {
                    return const FaqScreen();
                  }
                  return FaqDetailScreen(item: ChristMeetsFaq.items[index]);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (context, state) => ChatScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
