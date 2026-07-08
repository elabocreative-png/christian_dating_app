import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/features/discovery/domain/account_visibility.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/domain/nearby_user.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/features/settings/data/block_repository.dart';

/// Discovery-specific data access: deck loading, distance enrichment, preferences.
class DiscoveryRepository {
  DiscoveryRepository(
    this._profileRepository,
    this._blockRepository, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final ProfileRepository _profileRepository;
  final BlockRepository _blockRepository;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  GeoCoordinate? _cachedViewerLocation;
  String? _cachedViewerUid;

  Future<Map<String, dynamic>> fetchViewerProfile(String uid) async {
    return Map<String, dynamic>.from(
      await _profileRepository.fetchProfile(uid) ?? <String, dynamic>{},
    );
  }

  Future<void> markDiscoveryHintsComplete(String uid) async {
    await _profileRepository.updateProfile(uid, {
      'discoveryHintsComplete': true,
    });
  }

  Future<String> fetchDiscoveryMode(String uid) async {
    final data = await _profileRepository.fetchProfile(uid);
    return data?['discoveryMode']?.toString() == kDiscoveryModeSocial
        ? kDiscoveryModeSocial
        : kDiscoveryModeDating;
  }

  void invalidateViewerCache() {
    _cachedViewerLocation = null;
    _cachedViewerUid = null;
  }

  Future<GeoCoordinate?> _viewerLocation(String uid) async {
    if (_cachedViewerUid == uid && _cachedViewerLocation != null) {
      return _cachedViewerLocation;
    }
    final meData = await _profileRepository.fetchProfile(uid);
    _cachedViewerUid = uid;
    _cachedViewerLocation = parseUserGeoPoint(meData?['location']);
    return _cachedViewerLocation;
  }

  /// Distance in km from [viewerUid] to [other], or null if unknown.
  Future<double?> distanceKmToProfile(
    Map<String, dynamic> other, {
    required String viewerUid,
  }) async {
    final myLocation = await _viewerLocation(viewerUid);
    final theirLocation = parseUserGeoPoint(other['location']);
    if (myLocation == null || theirLocation == null) return null;
    return distanceKmBetween(myLocation, theirLocation);
  }

  /// Copy of [user] with `distanceKm` set when coordinates allow.
  Future<Map<String, dynamic>> enrichWithDistance(
    Map<String, dynamic> user, {
    required String viewerUid,
  }) async {
    final copy = Map<String, dynamic>.from(user);
    final km = await distanceKmToProfile(user, viewerUid: viewerUid);
    if (km != null) copy['distanceKm'] = km;
    return copy;
  }

  Future<List<NearbyUser>> fetchNearbyUsers(String uid) async {
    final myLocation = await _viewerLocation(uid);
    final meData = await _profileRepository.fetchProfile(uid);
    final maxKm =
        (meData?['maxDistanceKm'] as num?)?.toDouble() ?? kDefaultMaxDistanceKm;
    final minAge =
        (meData?['discoveryMinAge'] as num?)?.round() ?? kDefaultDiscoveryMinAge;
    final maxAge =
        (meData?['discoveryMaxAge'] as num?)?.round() ?? kDefaultDiscoveryMaxAge;
    final discoveryMode =
        meData?['discoveryMode']?.toString() == kDiscoveryModeSocial
            ? kDiscoveryModeSocial
            : kDiscoveryModeDating;
    final interestedIn = interestedInForDiscoveryDeck(
      discoveryMode,
      viewerGender: meData?['gender']?.toString(),
    );

    final snapshot = await _db.collection('users').get();

    final outgoingLikes = await _db
        .collection('likes')
        .where('fromUserId', isEqualTo: uid)
        .get();
    final incomingLikes = await _db
        .collection('likes')
        .where('toUserId', isEqualTo: uid)
        .get();
    final matches = await _db
        .collection('matches')
        .where('users', arrayContains: uid)
        .get();

    final matchedUserIds = <String>{};
    for (final match in matches.docs) {
      final users = match.data()['users'];
      if (users is! List) continue;
      for (final userId in users) {
        final id = userId.toString();
        if (id.isNotEmpty && id != uid) {
          matchedUserIds.add(id);
        }
      }
    }

    final interactionModes = interactionModeByUserId(
      outgoingLikes: outgoingLikes.docs.map((doc) => doc.data()),
      incomingLikes: incomingLikes.docs.map((doc) => doc.data()),
      matchedUserIds: matchedUserIds,
    );
    final blockedUserIds = await _blockRepository.fetchBlockedUserIds(uid);

    final ranked = <NearbyUser>[];

    for (final doc in snapshot.docs) {
      if (doc.id == uid) continue;
      if (blockedUserIds.contains(doc.id)) continue;

      final interactionMode = interactionModes[doc.id];
      if (shouldExcludeUserFromDiscoveryDeck(
        deckMode: discoveryMode,
        interactionMode: interactionMode,
      )) {
        continue;
      }

      final data = doc.data();

      if (isAccountDeactivated(data)) continue;

      if (!profileMatchesInterestedIn(interestedIn, data)) continue;

      final theirAge = (data['age'] as num?)?.round();
      if (theirAge != null && (theirAge < minAge || theirAge > maxAge)) {
        continue;
      }

      final theirLocation = parseUserGeoPoint(data['location']);
      double? distanceKm;

      if (myLocation != null && theirLocation != null) {
        distanceKm = distanceKmBetween(myLocation, theirLocation);
        if (distanceKm > maxKm) continue;
      }

      ranked.add(
        NearbyUser(
          id: doc.id,
          profile: Map<String, dynamic>.from(data),
          distanceKm: distanceKm,
        ),
      );
    }

    ranked.sort((a, b) {
      final ad = a.distanceKm;
      final bd = b.distanceKm;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    return ranked;
  }

  Future<void> saveDiscoveryPreferences(
    String uid, {
    required String mode,
    required int maxDistanceKm,
    required int minAge,
    required int maxAge,
    required String interestedIn,
  }) async {
    await _profileRepository.mergeProfile(uid, {
      'discoveryMode': mode,
      'maxDistanceKm': maxDistanceKm,
      'discoveryMinAge': minAge,
      'discoveryMaxAge': maxAge,
      'interestedIn': interestedIn,
    });
    invalidateViewerCache();
  }

  Future<void> saveDiscoveryMode(String uid, String mode) async {
    final data = await _profileRepository.fetchProfile(uid);
    final interestedIn = interestedInForModeSwitch(
      newMode: mode,
      currentInterestedIn: data?['interestedIn']?.toString(),
      viewerGender: data?['gender']?.toString(),
    );
    await _profileRepository.mergeProfile(uid, {
      'discoveryMode': mode,
      'datingDiscoveryEnabled': mode == kDiscoveryModeDating,
      'socialDiscoveryEnabled': mode == kDiscoveryModeSocial,
      'interestedIn': interestedIn,
    });
    invalidateViewerCache();
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(
    ref.watch(profileRepositoryProvider),
    ref.watch(blockRepositoryProvider),
  );
});
