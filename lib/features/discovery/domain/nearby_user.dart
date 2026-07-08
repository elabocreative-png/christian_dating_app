/// A discoverable user plus optional distance from the current viewer.
class NearbyUser {
  const NearbyUser({
    required this.id,
    required this.profile,
    this.distanceKm,
  });

  final String id;
  final Map<String, dynamic> profile;
  final double? distanceKm;

  Map<String, dynamic> get profileData {
    final data = Map<String, dynamic>.from(profile);
    if (distanceKm != null) {
      data['distanceKm'] = distanceKm;
    }
    return data;
  }
}
