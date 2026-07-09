import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';

void main() {
  group('AppRoutes.isHomeShellRoute', () {
    test('returns true for home shell paths', () {
      for (final path in [
        AppRoutes.home,
        ...AppRoutes.homeTabRoutes,
      ]) {
        expect(AppRoutes.isHomeShellRoute(path), isTrue, reason: path);
      }
    });

    test('returns false for non-shell paths', () {
      expect(AppRoutes.isHomeShellRoute(AppRoutes.settings), isFalse);
      expect(AppRoutes.isHomeShellRoute(AppRoutes.chat('match-1')), isFalse);
      expect(AppRoutes.isHomeShellRoute(AppRoutes.login), isFalse);
    });
  });
}
