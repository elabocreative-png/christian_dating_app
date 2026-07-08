import 'dart:math' as math;

/// A latitude/longitude pair without Firestore types.
class GeoCoordinate {
  const GeoCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Default discovery radius when the user has not set a preference.
const double kDefaultMaxDistanceKm = 100;

/// Parses a Firestore GeoPoint-like value or legacy `{latitude, longitude}` map.
GeoCoordinate? parseUserGeoPoint(dynamic value) {
  if (value == null) return null;

  if (value is GeoCoordinate) return value;

  try {
    final lat = (value as dynamic).latitude;
    final lng = (value as dynamic).longitude;
    if (lat is num && lng is num) {
      return GeoCoordinate(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
      );
    }
  } catch (_) {}

  if (value is Map) {
    final lat = value['latitude'] ?? value['lat'];
    final lng = value['longitude'] ?? value['lng'];
    if (lat is num && lng is num) {
      return GeoCoordinate(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
      );
    }
  }
  return null;
}

/// Great-circle distance in kilometers (Haversine).
double distanceKmBetween(GeoCoordinate a, GeoCoordinate b) {
  const earthRadiusKm = 6371.0;
  final lat1 = _toRadians(a.latitude);
  final lat2 = _toRadians(b.latitude);
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);

  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final h = sinDLat * sinDLat +
      math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
  return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _toRadians(double degrees) => degrees * math.pi / 180;

const double _kmPerMile = 0.621371;

double kmToMiles(double km) => km * _kmPerMile;

/// User-facing distance (miles), e.g. "1 mile away".
String formatDistanceAway(double km) {
  final miles = kmToMiles(km);
  if (miles < 0.1) return 'Less than 0.1 miles away';
  if (miles < 1) return 'Less than 1 mile away';
  if (miles < 10) {
    final rounded = double.parse(miles.toStringAsFixed(1));
    final unit = rounded == 1.0 ? 'mile' : 'miles';
    return '$rounded $unit away';
  }
  final rounded = miles.round();
  final unit = rounded == 1 ? 'mile' : 'miles';
  return '$rounded $unit away';
}

String profileCityLabel(Map<String, dynamic> user) {
  return user['city']?.toString().trim() ?? '';
}

bool hasProfileCityLabel(Map<String, dynamic> user) {
  return profileCityLabel(user).isNotEmpty;
}

String? distanceAwayLabel(Map<String, dynamic> user) {
  final rawDistance = user['distanceKm'];
  if (rawDistance is! num) return null;
  return formatDistanceAway(rawDistance.toDouble());
}

/// Compact distance for hero pill, e.g. "4 km".
String formatDistanceKmShort(double km) {
  if (km < 1) return 'Less than 1 km';
  final rounded = km.round();
  return '$rounded km';
}

/// Compact distance from user map, e.g. "4 km".
String? distanceKmShortLabel(Map<String, dynamic> user) {
  final rawDistance = user['distanceKm'];
  if (rawDistance is! num) return null;
  return formatDistanceKmShort(rawDistance.toDouble());
}

bool hasDistanceAwayLabel(Map<String, dynamic> user) {
  return distanceAwayLabel(user) != null;
}

/// Hero city pill only (distance lives in the Location section).
String locationHeroLabel(Map<String, dynamic> user) => profileCityLabel(user);

bool hasLocationHeroLabel(Map<String, dynamic> user) => hasProfileCityLabel(user);

/// Profile location pill, e.g. "4 miles away. Lusaka, Zambia".
String? profileLocationPillLabel(
  Map<String, dynamic> user, {
  double? distanceKm,
}) {
  final distance =
      distanceKm != null ? formatDistanceAway(distanceKm) : distanceAwayLabel(user);
  final city = profileCityLabel(user);

  if (distance != null && city.isNotEmpty) {
    return '$distance. $city';
  }
  if (distance != null) return distance;
  if (city.isNotEmpty) return city;
  return null;
}
