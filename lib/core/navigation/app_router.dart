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
