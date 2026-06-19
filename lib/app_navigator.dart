import 'package:flutter/material.dart';

import 'widgets/app_icon.dart';

/// Root navigator for notification deep links and global routes.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route name for [MatchPopupScreen] (see match_popup_screen.dart).
const String kMatchPopupRouteName = '/match-popup';

final MatchPopupNavigatorObserver matchPopupNavigatorObserver =
    MatchPopupNavigatorObserver();

/// Keeps OEM nav bar styling in sync with match popup push/pop.
class MatchPopupNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == kMatchPopupRouteName) {
      applyMatchSystemNavigationBar();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == kMatchPopupRouteName) {
      restoreAppSystemNavigationBar();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route.settings.name == kMatchPopupRouteName) {
      restoreAppSystemNavigationBar();
    }
  }
}
