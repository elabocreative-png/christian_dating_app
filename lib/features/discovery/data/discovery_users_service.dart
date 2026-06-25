import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/features/discovery/domain/account_visibility.dart';
import 'package:christian_dating_app/core/services/block_service.dart';

/// Cached viewer location for repeated distance lookups in a session.
GeoPoint? _cachedViewerLocation;
String? _cachedViewerUid;

/// A discoverable user plus optional distance from the current viewer.
class NearbyUser {
  const NearbyUser({
    required this.document,
    this.distanceKm,
  });

  final DocumentSnapshot document;
  final double? distanceKm;

  String get id => document.id;

  Map<String, dynamic> get profileData {
    final raw = document.data();
    final data = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    if (distanceKm != null) {
      data['distanceKm'] = distanceKm;
    }
    return data;
  }
}

/// Loads users for discovery, sorted by distance when coordinates exist.
class DiscoveryUsersService {
  static void invalidateViewerCache() {
    _cachedViewerLocation = null;
    _cachedViewerUid = null;
  }

  static Future<GeoPoint?> _viewerLocation() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return null;
    if (_cachedViewerUid == authUser.uid && _cachedViewerLocation != null) {
      return _cachedViewerLocation;
    }
    final meSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(authUser.uid)
        .get();
    _cachedViewerUid = authUser.uid;
    _cachedViewerLocation = parseUserGeoPoint(meSnap.data()?['location']);
    return _cachedViewerLocation;
  }

  /// Distance in km from the signed-in user to [other], or null if unknown.
  static Future<double?> distanceKmToProfile(Map<String, dynamic> other) async {
    final myLocation = await _viewerLocation();
    final theirLocation = parseUserGeoPoint(other['location']);
    if (myLocation == null || theirLocation == null) return null;
    return distanceKmBetween(myLocation, theirLocation);
  }

  /// Copy of [user] with `distanceKm` set when coordinates allow.
  static Future<Map<String, dynamic>> enrichWithDistance(
    Map<String, dynamic> user,
  ) async {
    final copy = Map<String, dynamic>.from(user);
    final km = await distanceKmToProfile(user);
    if (km != null) copy['distanceKm'] = km;
    return copy;
  }

  static Future<List<NearbyUser>> fetchNearbyUsers() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return [];

    final myLocation = await _viewerLocation();
    final meSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(authUser.uid)
        .get();
    final meData = meSnap.data();
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

    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final outgoingLikes = await FirebaseFirestore.instance
        .collection('likes')
        .where('fromUserId', isEqualTo: authUser.uid)
        .get();
    final incomingLikes = await FirebaseFirestore.instance
        .collection('likes')
        .where('toUserId', isEqualTo: authUser.uid)
        .get();
    final matches = await FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: authUser.uid)
        .get();

    final matchedUserIds = <String>{};
    for (final match in matches.docs) {
      final users = match.data()['users'];
      if (users is! List) continue;
      for (final userId in users) {
        final id = userId.toString();
        if (id.isNotEmpty && id != authUser.uid) {
          matchedUserIds.add(id);
        }
      }
    }

    final interactionModes = interactionModeByUserId(
      outgoingLikes: outgoingLikes.docs.map((doc) => doc.data()),
      incomingLikes: incomingLikes.docs.map((doc) => doc.data()),
      matchedUserIds: matchedUserIds,
    );
    final blockedUserIds = await BlockService.fetchBlockedUserIds();

    final ranked = <NearbyUser>[];

    for (final doc in snapshot.docs) {
      if (doc.id == authUser.uid) continue;
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
          document: doc,
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
}
