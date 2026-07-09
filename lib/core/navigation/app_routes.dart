/// Central route paths for [GoRouter].
abstract final class AppRoutes {
  static const loading = '/loading';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static const settings = '/settings';
  static const settingsHelp = '/settings/help';
  static const settingsReport = '/settings/report';
  static const settingsBlocked = '/settings/blocked';
  static const settingsDeactivate = '/settings/deactivate';
  static const settingsTerms = '/settings/terms';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsFaq = '/settings/faq';

  static String chat(String matchId) => '/chat/$matchId';
  static String settingsFaqItem(int index) => '/settings/faq/$index';
  static const profileEdit = '/profile/edit';
}
