import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/constants/gender_options.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/features/settings/data/block_repository.dart';

void main() {
  group('DiscoveryRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late ProfileRepository profileRepo;
    late BlockRepository blockRepo;
    late DiscoveryRepository repo;

    const viewerId = 'viewer';
    const nearId = 'near-user';
    const farId = 'far-user';

    // NYC and nearby coordinates for distance filtering.
    const viewerLocation = {'latitude': 40.7128, 'longitude': -74.0060};
    const nearLocation = {'latitude': 40.7580, 'longitude': -73.9855};
    const farLocation = {'latitude': 42.3601, 'longitude': -71.0589};

    setUp(() {
      firestore = FakeFirebaseFirestore();
      profileRepo = ProfileRepository(firestore: firestore);
      blockRepo = BlockRepository(firestore: firestore);
      repo = DiscoveryRepository(
        profileRepo,
        blockRepo,
        firestore: firestore,
      );
    });

    Future<void> seedViewer({
      double maxDistanceKm = 100,
      int minAge = 18,
      int maxAge = 40,
      String mode = kDiscoveryModeDating,
    }) {
      return firestore.collection('users').doc(viewerId).set({
        'gender': kGenderFemale,
        'discoveryMode': mode,
        'maxDistanceKm': maxDistanceKm,
        'discoveryMinAge': minAge,
        'discoveryMaxAge': maxAge,
        'location': viewerLocation,
      });
    }

    Future<void> seedCandidate({
      required String id,
      required Map<String, dynamic> location,
      String gender = kGenderMale,
      int age = 25,
      bool deactivated = false,
    }) {
      return firestore.collection('users').doc(id).set({
        'gender': gender,
        'age': age,
        'location': location,
        if (deactivated) 'accountDeactivated': true,
      });
    }

    test('fetchDiscoveryMode defaults to dating', () async {
      await firestore.collection('users').doc(viewerId).set({});
      expect(await repo.fetchDiscoveryMode(viewerId), kDiscoveryModeDating);
    });

    test('fetchDiscoveryMode returns social when set', () async {
      await firestore.collection('users').doc(viewerId).set({
        'discoveryMode': kDiscoveryModeSocial,
      });
      expect(await repo.fetchDiscoveryMode(viewerId), kDiscoveryModeSocial);
    });

    test('fetchViewerProfile returns profile map', () async {
      await firestore.collection('users').doc(viewerId).set({
        'displayName': 'Alex',
      });
      final profile = await repo.fetchViewerProfile(viewerId);
      expect(profile['displayName'], 'Alex');
    });

    test('markDiscoveryHintsComplete updates profile', () async {
      await firestore.collection('users').doc(viewerId).set({});
      await repo.markDiscoveryHintsComplete(viewerId);
      final data = (await firestore.collection('users').doc(viewerId).get())
          .data();
      expect(data?['discoveryHintsComplete'], isTrue);
    });

    test('saveDiscoveryPreferences merges fields', () async {
      await firestore.collection('users').doc(viewerId).set({});
      await repo.saveDiscoveryPreferences(
        viewerId,
        mode: kDiscoveryModeSocial,
        maxDistanceKm: 60,
        minAge: 21,
        maxAge: 35,
        interestedIn: kInterestedInAnyone,
      );
      final data = (await firestore.collection('users').doc(viewerId).get())
          .data();
      expect(data?['discoveryMode'], kDiscoveryModeSocial);
      expect(data?['maxDistanceKm'], 60);
      expect(data?['discoveryMinAge'], 21);
      expect(data?['discoveryMaxAge'], 35);
      expect(data?['interestedIn'], kInterestedInAnyone);
    });

    test('saveDiscoveryMode switches to social with Anyone interested', () async {
      await firestore.collection('users').doc(viewerId).set({
        'gender': kGenderFemale,
        'discoveryMode': kDiscoveryModeDating,
        'interestedIn': kInterestedInMen,
      });
      await repo.saveDiscoveryMode(viewerId, kDiscoveryModeSocial);
      final data = (await firestore.collection('users').doc(viewerId).get())
          .data();
      expect(data?['discoveryMode'], kDiscoveryModeSocial);
      expect(data?['socialDiscoveryEnabled'], isTrue);
      expect(data?['datingDiscoveryEnabled'], isFalse);
      expect(data?['interestedIn'], kInterestedInAnyone);
    });

    test('distanceKmToProfile returns km when both have location', () async {
      await seedViewer();
      await seedCandidate(id: nearId, location: nearLocation);
      final other =
          (await firestore.collection('users').doc(nearId).get()).data()!;
      final km = await repo.distanceKmToProfile(
        other,
        viewerUid: viewerId,
      );
      expect(km, isNotNull);
      expect(km!, greaterThan(0));
      expect(km, lessThan(20));
    });

    test('distanceKmToProfile returns null when location missing', () async {
      await firestore.collection('users').doc(viewerId).set({});
      final km = await repo.distanceKmToProfile(
        const {},
        viewerUid: viewerId,
      );
      expect(km, isNull);
    });

    test('enrichWithDistance adds distanceKm to copy', () async {
      await seedViewer();
      await seedCandidate(id: nearId, location: nearLocation);
      final other =
          (await firestore.collection('users').doc(nearId).get()).data()!;
      final enriched =
          await repo.enrichWithDistance(other, viewerUid: viewerId);
      expect(enriched['distanceKm'], isA<num>());
      expect(other.containsKey('distanceKm'), isFalse);
    });

    test('fetchNearbyUsers returns eligible users sorted by distance', () async {
      await seedViewer(maxDistanceKm: 500);
      await seedCandidate(id: nearId, location: nearLocation);
      await seedCandidate(id: farId, location: farLocation);

      final nearby = await repo.fetchNearbyUsers(viewerId);
      expect(nearby.map((u) => u.id).toList(), [nearId, farId]);
      expect(nearby.first.distanceKm, lessThan(nearby.last.distanceKm!));
    });

    test('fetchNearbyUsers excludes self blocked wrong gender age far and deactivated',
        () async {
      await seedViewer(maxDistanceKm: 50, minAge: 22, maxAge: 30);
      await seedCandidate(id: nearId, location: nearLocation, age: 25);
      await seedCandidate(
        id: 'blocked-user',
        location: nearLocation,
        age: 25,
      );
      await seedCandidate(
        id: 'female-user',
        location: nearLocation,
        gender: kGenderFemale,
        age: 25,
      );
      await seedCandidate(
        id: 'young-user',
        location: nearLocation,
        age: 18,
      );
      await seedCandidate(
        id: 'old-user',
        location: nearLocation,
        age: 45,
      );
      await seedCandidate(
        id: farId,
        location: farLocation,
        age: 25,
      );
      await seedCandidate(
        id: 'deactivated-user',
        location: nearLocation,
        age: 25,
        deactivated: true,
      );

      await blockRepo.blockUser(
        uid: viewerId,
        blockedUserId: 'blocked-user',
        source: BlockSource.discovery,
      );

      final ids = (await repo.fetchNearbyUsers(viewerId))
          .map((u) => u.id)
          .toSet();
      expect(ids, {nearId});
    });

    test('fetchNearbyUsers excludes user with prior dating like', () async {
      await seedViewer(maxDistanceKm: 500);
      await seedCandidate(id: nearId, location: nearLocation);
      await firestore.collection('likes').add({
        'fromUserId': viewerId,
        'toUserId': nearId,
        'discoveryMode': kDiscoveryModeDating,
      });

      final nearby = await repo.fetchNearbyUsers(viewerId);
      expect(nearby.map((u) => u.id), isEmpty);
    });

    test('invalidateViewerCache forces location re-read', () async {
      await seedViewer();
      await seedCandidate(id: nearId, location: nearLocation);
      final other =
          (await firestore.collection('users').doc(nearId).get()).data()!;

      final first = await repo.distanceKmToProfile(other, viewerUid: viewerId);
      expect(first, isNotNull);

      await firestore.collection('users').doc(viewerId).update({
        'location': farLocation,
      });
      repo.invalidateViewerCache();

      final second =
          await repo.distanceKmToProfile(other, viewerUid: viewerId);
      expect(second, isNotNull);
      expect(second!, greaterThan(first!));
    });
  });
}
