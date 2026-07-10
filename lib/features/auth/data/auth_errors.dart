import 'package:firebase_auth/firebase_auth.dart';

/// User-facing copy for Firebase Auth failures.
String messageForAuthException(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// User-facing copy when onboarding profile save fails.
String onboardingProfileSaveErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return messageForAuthException(error);
  }
  return 'Could not save profile: $error';
}
