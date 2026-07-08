/// Central route paths for [GoRouter].
abstract final class AppRoutes {
  static const loading = '/loading';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static String chat(String matchId) => '/chat/$matchId';
}
