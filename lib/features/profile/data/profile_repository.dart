import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';

/// Data access for user profile documents.
///
/// Returns plain app maps so the presentation layer never touches
/// cloud_firestore types directly.
class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Live profile document for [uid]; emits null when the document is absent.
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _userRef(uid).snapshots().map((doc) => doc.data());
  }

  /// One-shot read of the profile document for [uid].
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final doc = await _userRef(uid).get();
    return doc.data();
  }

  /// Reads the profile, creating a blank default document when absent.
  Future<Map<String, dynamic>> fetchOrEnsureProfile(String uid) async {
    final doc = await _userRef(uid).get();
    if (!doc.exists) {
      await _userRef(uid).set(_defaultProfileFields());
    }
    final data = (await _userRef(uid).get()).data();
    return Map<String, dynamic>.from(data ?? _defaultProfileFields());
  }

  /// Partial update of profile fields for [uid].
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    await _userRef(uid).update(updates);
  }

  /// Creates or merges profile fields for [uid] without replacing the document.
  Future<void> mergeProfile(String uid, Map<String, dynamic> updates) async {
    await _userRef(uid).set(updates, SetOptions(merge: true));
  }

  /// Registers an FCM device token on the user's profile.
  Future<void> addFcmToken(String uid, String token) async {
    if (token.isEmpty) return;
    await mergeProfile(uid, {
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes an FCM device token from the user's profile.
  Future<void> removeFcmToken(String uid, String token) async {
    if (token.isEmpty) return;
    await mergeProfile(uid, {
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  /// Writes a full profile document (e.g. first save after deferred sign-up).
  Future<void> setProfile(String uid, Map<String, dynamic> data) async {
    await _userRef(uid).set(data);
  }

  /// Fetches multiple user profiles by id in Firestore `whereIn` chunks.
  Future<Map<String, Map<String, dynamic>>> fetchProfilesByIds(
    Iterable<String> userIds,
  ) async {
    const whereInLimit = 30;
    final ids = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return {};

    final results = <String, Map<String, dynamic>>{};

    for (var i = 0; i < ids.length; i += whereInLimit) {
      final end =
          i + whereInLimit > ids.length ? ids.length : i + whereInLimit;
      final chunk = ids.sublist(i, end);

      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        results[doc.id] = doc.data();
      }
    }

    return results;
  }

  Map<String, dynamic> _defaultProfileFields() {
    return {
      'name': '',
      'age': 18,
      'city': '',
      'aboutMe': '',
      'interests': <String>[],
      'photos': [],
      'photoThumbs': [],
      'prompts': [
        {'question': '', 'answer': ''},
        {'question': '', 'answer': ''},
      ],
      'denomination': null,
      'speaksInTongues': null,
      'faithLevel': null,
      'churchAttendance': null,
      'churchName': '',
      'exercise': null,
      'lookingFor': kDefaultLookingFor,
      'alcohol': null,
      'smoking': null,
      'gender': null,
      'kids': null,
      'bodyType': null,
      'personality': null,
      'tattoos': null,
      'heightInches': null,
      'profileComplete': false,
      'maxDistanceKm': kDefaultMaxDistanceKm.round(),
    };
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
