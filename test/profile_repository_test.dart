import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

void main() {
  group('ProfileRepository guards', () {
    test('fetchProfilesByIds returns empty map for no ids', () async {
      final repo = ProfileRepository(firestore: FakeFirebaseFirestore());
      final result = await repo.fetchProfilesByIds([]);
      expect(result, isEmpty);
    });

    test('fetchProfilesByIds ignores empty id strings', () async {
      final repo = ProfileRepository(firestore: FakeFirebaseFirestore());
      final result = await repo.fetchProfilesByIds(['', '  ']);
      expect(result, isEmpty);
    });

    test('addFcmToken and removeFcmToken no-op for empty token', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = ProfileRepository(firestore: firestore);
      await firestore.collection('users').doc('user-1').set({});

      await repo.addFcmToken('user-1', '');
      await repo.removeFcmToken('user-1', '');

      final data = (await firestore.collection('users').doc('user-1').get())
          .data();
      expect(data?.containsKey('fcmTokens'), isFalse);
    });
  });

  group('ProfileRepository.initialSignupProfileFields', () {
    test('includes onboarding defaults and email', () {
      final repo = ProfileRepository(firestore: FakeFirebaseFirestore());
      final fields = repo.initialSignupProfileFields('  user@example.com  ');

      expect(fields['email'], 'user@example.com');
      expect(fields['discoveryMode'], 'dating');
      expect(fields['discoveryMinAge'], 18);
      expect(fields['discoveryMaxAge'], 40);
      expect(fields['interestedIn'], 'Anyone');
      expect(fields['lookingFor'], kDefaultLookingFor);
      expect(fields['fcmTokens'], isEmpty);
      expect(fields['prompts'], hasLength(2));
    });
  });

  group('ProfileRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late ProfileRepository repo;
    const uid = 'user-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = ProfileRepository(firestore: firestore);
    });

    test('fetchProfile returns null when document missing', () async {
      expect(await repo.fetchProfile(uid), isNull);
    });

    test('fetchOrEnsureProfile creates default document when absent', () async {
      final profile = await repo.fetchOrEnsureProfile(uid);

      expect(profile['name'], '');
      expect(profile['age'], 18);
      expect(profile['maxDistanceKm'], kDefaultMaxDistanceKm.round());
      expect(profile['profileComplete'], isFalse);

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.exists, isTrue);
    });

    test('updateProfile patches existing fields', () async {
      await firestore.collection('users').doc(uid).set({'name': 'Before'});
      await repo.updateProfile(uid, {'name': 'After', 'city': 'NYC'});

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['name'], 'After');
      expect(data?['city'], 'NYC');
    });

    test('mergeProfile merges without replacing document', () async {
      await firestore.collection('users').doc(uid).set({
        'name': 'Alex',
        'city': 'Boston',
      });
      await repo.mergeProfile(uid, {'city': 'NYC', 'age': 28});

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['name'], 'Alex');
      expect(data?['city'], 'NYC');
      expect(data?['age'], 28);
    });

    test('setProfile replaces document', () async {
      await firestore.collection('users').doc(uid).set({'name': 'Old'});
      await repo.setProfile(uid, {'name': 'New'});

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data, {'name': 'New'});
    });

    test('watchProfile emits profile updates', () async {
      await firestore.collection('users').doc(uid).set({'name': 'First'});

      final first = await repo.watchProfile(uid).first;
      expect(first?['name'], 'First');

      await repo.updateProfile(uid, {'name': 'Second'});
      final second = await repo.watchProfile(uid).first;
      expect(second?['name'], 'Second');
    });

    test('fetchProfilesByIds returns profiles for requested ids', () async {
      await firestore.collection('users').doc('user-a').set({'name': 'A'});
      await firestore.collection('users').doc('user-b').set({'name': 'B'});
      await firestore.collection('users').doc('user-c').set({'name': 'C'});

      final profiles = await repo.fetchProfilesByIds([
        'user-a',
        'user-b',
        '',
        'missing',
      ]);

      expect(profiles.keys, {'user-a', 'user-b'});
      expect(profiles['user-a']?['name'], 'A');
      expect(profiles['user-b']?['name'], 'B');
    });

    test('addFcmToken and removeFcmToken manage token list', () async {
      await firestore.collection('users').doc(uid).set({'fcmTokens': []});

      await repo.addFcmToken(uid, 'token-a');
      await repo.addFcmToken(uid, 'token-b');

      var data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['fcmTokens'], containsAll(['token-a', 'token-b']));

      await repo.removeFcmToken(uid, 'token-a');
      data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['fcmTokens'], ['token-b']);
    });

    test('deactivateAccount sets deactivation fields', () async {
      await firestore.collection('users').doc(uid).set({'name': 'Alex'});
      await repo.deactivateAccount(uid, reason: '  taking a break  ');

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['accountDeactivated'], isTrue);
      expect(data?['deactivationReason'], 'taking a break');
      expect(data?['deactivatedAt'], isNotNull);
    });

    test('reactivateIfDeactivated clears flag when deactivated', () async {
      await firestore.collection('users').doc(uid).set({
        'accountDeactivated': true,
      });

      await repo.reactivateIfDeactivated(uid);

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['accountDeactivated'], isFalse);
      expect(data?['reactivatedAt'], isNotNull);
    });

    test('reactivateIfDeactivated no-ops when account is active', () async {
      await firestore.collection('users').doc(uid).set({
        'accountDeactivated': false,
        'name': 'Alex',
      });

      await repo.reactivateIfDeactivated(uid);

      final data = (await firestore.collection('users').doc(uid).get()).data();
      expect(data?['accountDeactivated'], isFalse);
      expect(data?.containsKey('reactivatedAt'), isFalse);
      expect(data?['name'], 'Alex');
    });

    test('deleteProfile removes user document', () async {
      await firestore.collection('users').doc(uid).set({'name': 'Alex'});
      await repo.deleteProfile(uid);

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.exists, isFalse);
    });
  });
}
