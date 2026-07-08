import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:christian_dating_app/features/settings/data/push_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Default Firestore fields for a newly registered user.
  static Map<String, dynamic> defaultUserFields(String email) {
    return {
      'email': email.trim(),
      'createdAt': Timestamp.now(),
      'name': '',
      'city': '',
      'gender': null,
      'kids': null,
      'bodyType': null,
      'heightInches': null,
      'maxDistanceKm': 100,
      'discoveryMode': 'dating',
      'datingDiscoveryEnabled': true,
      'socialDiscoveryEnabled': true,
      'discoveryMinAge': 18,
      'discoveryMaxAge': 40,
      'interestedIn': 'Anyone',
      'aboutMe': '',
      'interests': <String>[],
      'photos': [],
      'photoThumbs': [],
      'prompts': [
        {'question': 'My relationship with God is...', 'answer': ''},
        {'question': 'My favorite Bible verse is...', 'answer': ''},
      ],
      'denomination': null,
      'speaksInTongues': null,
      'faithLevel': null,
      'churchAttendance': null,
      'churchName': '',
      'exercise': null,
      'personality': null,
      'tattoos': null,
      'alcohol': null,
      'smoking': null,
      'profileComplete': false,
      'discoveryHintsComplete': false,
      'onboardingStep': 0,
      'onboardingDiscoveryPrefsComplete': false,
      'fcmTokens': <String>[],
    };
  }

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
        await reactivateAccountIfNeeded(user.uid);
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

  // LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user;
      if (user != null) {
        await reactivateAccountIfNeeded(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  /// Clears deactivation when a user signs back in.
  Future<void> reactivateAccountIfNeeded(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.data()?['accountDeactivated'] != true) return;
    await ref.update({
      'accountDeactivated': false,
      'reactivatedAt': Timestamp.now(),
    });
  }

  /// Hides the profile from other users while keeping data intact.
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
    await PushNotificationService.clearTokenForUser(uid);
    await _db.collection('users').doc(uid).update({
      'accountDeactivated': true,
      'deactivatedAt': Timestamp.now(),
      'deactivationReason': trimmedReason,
    });
    await _auth.signOut();
  }

  // LOGOUT
  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await PushNotificationService.clearTokenForUser(uid);
    }
    await _auth.signOut();
  }

  /// Deletes the Firestore user document then the Firebase Auth user.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    try {
      await PushNotificationService.clearTokenForUser(uid);
      await _db.collection('users').doc(uid).delete();
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
