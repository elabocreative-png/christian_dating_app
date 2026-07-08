import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/chat/presentation/chat_screen.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/main_navigation.dart';

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Android push notifications: chat messages + mutual matches.
abstract final class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ProfileRepository _profiles = ProfileRepository();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static StreamSubscription<String>? _tokenRefreshSub;
  static String? _pendingMatchId;

  static const String chatMessageType = 'chat_message';
  static const String newMatchType = 'new_match';

  /// Call once after [Firebase.initializeApp].
  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationOpen(initial);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(_saveToken(uid, token));
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await syncTokenForUser(user.uid);
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Saves FCM token on the signed-in user's profile.
  static Future<void> syncTokenForUser(String uid) async {
    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(uid, token);
    } catch (_) {
      // Permission denied or Play Services unavailable — skip silently.
    }
  }

  /// Removes this device's token when signing out.
  static Future<void> clearTokenForUser(String uid) async {
    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) return;
      await _profiles.removeFcmToken(uid, token);
    } catch (_) {}
  }

  /// Call when [MainNavigation] is ready (handles cold-start notification).
  static void handlePendingNotification() {
    final matchId = _pendingMatchId;
    if (matchId == null || matchId.isEmpty) return;
    _pendingMatchId = null;
    openChat(matchId);
  }

  static void openChat(String matchId) {
    if (matchId.isEmpty) return;

    mainNavigationKey.currentState?.selectChatsTab();

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingMatchId = matchId;
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(matchId: matchId),
      ),
    );
  }

  static Future<void> _requestPermission() async {
    await requestUserPermission();
  }

  /// Onboarding / settings: system notification permission + token sync.
  static Future<void> requestUserPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await syncTokenForUser(uid);
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _profiles.addFcmToken(uid, token);
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    final type = message.data['type']?.toString();
    if (type != chatMessageType && type != newMatchType) return;

    final matchId = message.data['matchId']?.toString().trim() ?? '';
    if (matchId.isEmpty) return;
    _pendingMatchId = matchId;

    if (mainNavigationKey.currentState != null) {
      handlePendingNotification();
    }
  }
}
