import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/discovery/data/discovery_users_service.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/domain/nearby_user.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

/// Discovery-specific data access built on the shared profile repository and
/// deck loader service.
class DiscoveryRepository {
  DiscoveryRepository(this._profileRepository);

  final ProfileRepository _profileRepository;

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

  Future<List<NearbyUser>> fetchNearbyUsers(String uid) {
    return DiscoveryUsersService.fetchNearbyUsers(uid);
  }

  void invalidateViewerCache() {
    DiscoveryUsersService.invalidateViewerCache();
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(profileRepositoryProvider));
});
