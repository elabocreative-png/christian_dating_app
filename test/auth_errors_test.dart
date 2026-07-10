import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/auth/data/auth_errors.dart';

void main() {
  group('onboardingProfileSaveErrorMessage', () {
    test('maps FirebaseAuthException through messageForAuthException', () {
      expect(
        onboardingProfileSaveErrorMessage(
          FirebaseAuthException(code: 'weak-password'),
        ),
        'Use a stronger password (at least 6 characters).',
      );
    });

    test('wraps non-auth errors with profile save prefix', () {
      expect(
        onboardingProfileSaveErrorMessage(Exception('upload failed')),
        'Could not save profile: Exception: upload failed',
      );
    });
  });
}
