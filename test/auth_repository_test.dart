import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/features/settings/data/push_notification_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockPushNotificationService extends Mock implements PushNotificationService {}

class RecordingProfileRepository extends ProfileRepository {
  String? deactivatedUid;
  String? deactivateReason;
  String? deletedUid;
  String? reactivatedUid;

  @override
  Future<void> deactivateAccount(String uid, {required String reason}) async {
    deactivatedUid = uid;
    deactivateReason = reason;
  }

  @override
  Future<void> deleteProfile(String uid) async {
    deletedUid = uid;
  }

  @override
  Future<void> reactivateIfDeactivated(String uid) async {
    reactivatedUid = uid;
  }
}

void main() {
  late MockFirebaseAuth auth;
  late RecordingProfileRepository profiles;
  late MockPushNotificationService push;
  late AuthRepository repo;

  setUp(() {
    auth = MockFirebaseAuth();
    profiles = RecordingProfileRepository();
    push = MockPushNotificationService();
    when(() => push.clearTokenForUser(any())).thenAnswer((_) async {});
    repo = AuthRepository(
      auth: auth,
      profileRepository: profiles,
      pushNotificationService: push,
    );
  });

  group('deactivateAccount', () {
    test('throws when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        repo.deactivateAccount(reason: 'Taking a break'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Not signed in'),
        )),
      );
    });

    test('throws when reason is empty', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-1');
      when(() => auth.currentUser).thenReturn(user);

      await expectLater(
        repo.deactivateAccount(reason: '   '),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('reason'),
        )),
      );
    });

    test('clears token, deactivates profile, and signs out', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-1');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repo.deactivateAccount(reason: '  Taking a break  ');

      verify(() => push.clearTokenForUser('uid-1')).called(1);
      expect(profiles.deactivatedUid, 'uid-1');
      expect(profiles.deactivateReason, 'Taking a break');
      verify(() => auth.signOut()).called(1);
    });
  });

  group('logout', () {
    test('clears token and signs out when signed in', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-2');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => push.clearTokenForUser('uid-2')).called(1);
      verify(() => auth.signOut()).called(1);
    });

    test('signs out without clearing token when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repo.logout();

      verifyNever(() => push.clearTokenForUser(any()));
      verify(() => auth.signOut()).called(1);
    });
  });

  group('deleteAccount', () {
    test('throws when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        repo.deleteAccount(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Not signed in'),
        )),
      );
    });

    test('clears token, deletes profile, and deletes auth user', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-3');
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => auth.currentUser).thenReturn(user);

      await repo.deleteAccount();

      verify(() => push.clearTokenForUser('uid-3')).called(1);
      expect(profiles.deletedUid, 'uid-3');
      verify(() => user.delete()).called(1);
    });

    test('maps requires-recent-login to a friendly message', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-4');
      when(() => user.delete()).thenThrow(
        FirebaseAuthException(code: 'requires-recent-login'),
      );
      when(() => auth.currentUser).thenReturn(user);

      await expectLater(
        repo.deleteAccount(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('sign out and sign in again'),
        )),
      );
    });
  });

  group('login', () {
    test('reactivates profile on successful sign-in', () async {
      final user = MockUser();
      final credential = MockUserCredential();

      when(() => user.uid).thenReturn('uid-5');
      when(() => credential.user).thenReturn(user);
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final result = await repo.login('  user@test.com  ', ' secret ');

      expect(result, user);
      expect(profiles.reactivatedUid, 'uid-5');
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'secret',
        ),
      ).called(1);
    });

    test('throws auth message on FirebaseAuthException', () async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'wrong-password', message: 'Bad password'),
      );

      await expectLater(
        repo.login('user@test.com', 'wrong'),
        throwsA('Bad password'),
      );
    });
  });

  group('createOrSignInForDeferredSignup', () {
    test('returns current user when email already matches', () async {
      final user = MockUser();
      when(() => user.email).thenReturn('User@Test.com');
      when(() => auth.currentUser).thenReturn(user);

      final result = await repo.createOrSignInForDeferredSignup(
        '  user@test.com ',
        'password',
      );

      expect(result, user);
      verifyNever(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('currentUser helpers', () {
    test('currentUser returns auth current user', () {
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);

      expect(repo.currentUser, user);
    });

    test('reloadCurrentUser reloads signed-in user', () async {
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.reload()).thenAnswer((_) async {});

      await repo.reloadCurrentUser();

      verify(() => user.reload()).called(1);
    });

    test('reloadCurrentUser no-ops when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);

      await repo.reloadCurrentUser();
    });

    test('authStateChanges forwards auth stream', () {
      final stream = Stream<User?>.value(null);
      when(() => auth.authStateChanges()).thenAnswer((_) => stream);

      expect(repo.authStateChanges(), stream);
    });
  });
}
