import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';

/// Data access for user profile documents.
///
/// Returns plain app maps so the presentation layer never touches
/// cloud_firestore types directly.
class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

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
