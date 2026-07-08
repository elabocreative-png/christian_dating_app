import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/features/settings/data/push_notification_service.dart';

/// Firebase Auth sign-in/sign-up and account lifecycle orchestration.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    ProfileRepository? profileRepository,
    PushNotificationService? pushNotificationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profiles = profileRepository ?? ProfileRepository(),
        _push = pushNotificationService;

  final FirebaseAuth _auth;
  final ProfileRepository _profiles;
  final PushNotificationService? _push;

  /// Creates the Firebase Auth user only (no Firestore doc yet).
  Future<User> createAuthUser(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user;
      if (user == null) {
        throw Exception('Sign up failed');
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Finishes deferred onboarding: creates auth or signs in if email exists.
  Future<User> createOrSignInForDeferredSignup(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    final current = _auth.currentUser;
    if (current != null &&
        current.email?.trim().toLowerCase() == normalizedEmail) {
      return current;
    }

    try {
      return await createAuthUser(email, password);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;

      try {
        final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final user = result.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message:
                'An account already exists for this email. Sign in from the '
                'login screen to continue.',
          );
        }
        await _profiles.reactivateIfDeactivated(user.uid);
        return user;
      } on FirebaseAuthException catch (signInError) {
        if (signInError.code == 'wrong-password' ||
            signInError.code == 'invalid-credential') {
          throw FirebaseAuthException(
            code: signInError.code,
            message:
                'This email is already registered. Sign in from the login '
                'screen with your password to continue.',
          );
        }
        rethrow;
      }
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user;
      if (user != null) {
        await _profiles.reactivateIfDeactivated(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<void> deactivateAccount({required String reason}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Please provide a reason for deactivating your account');
    }

    final uid = user.uid;
    await _push?.clearTokenForUser(uid);
    await _profiles.deactivateAccount(uid, reason: trimmedReason);
    await _auth.signOut();
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _push?.clearTokenForUser(uid);
    }
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    try {
      await _push?.clearTokenForUser(uid);
      await _profiles.deleteProfile(uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Please sign out and sign in again, then try deleting your account.',
        );
      }
      throw Exception(e.message ?? 'Could not delete account');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    profileRepository: ref.watch(profileRepositoryProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
  );
});
