import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:christian_dating_app/core/utils/geo_utils.dart';

class UserLocationData {
  const UserLocationData({
    required this.coordinate,
    required this.city,
  });

  final GeoCoordinate coordinate;
  final String city;
}

class LocationPermissionDenied implements Exception {
  LocationPermissionDenied(this.message, {this.deniedForever = false});

  final String message;
  final bool deniedForever;

  @override
  String toString() => message;
}

class LocationServiceDisabled implements Exception {
  LocationServiceDisabled(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Device GPS + reverse geocoding for profile and discovery.
class LocationService {
  static bool isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Shows the OS location permission dialog when still needed.
  static Future<LocationPermission> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();

    if (isPermissionGranted(permission)) {
      return permission;
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDenied(
        'Location was permanently denied. Open Settings to allow access.',
        deniedForever: true,
      );
    }

    // denied or unableToDetermine → triggers Android/iOS system prompt.
    permission = await Geolocator.requestPermission();
    return permission;
  }

  static Future<void> ensurePermission() async {
    final permission = await requestLocationPermission();
    if (!isPermissionGranted(permission)) {
      final forever = permission == LocationPermission.deniedForever;
      throw LocationPermissionDenied(
        forever
            ? 'Location was permanently denied. Open Settings to allow access.'
            : 'Location permission is required to use your current position.',
        deniedForever: forever,
      );
    }
  }

  static Future<void> ensureLocationServicesEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabled(
        'Location services are turned off. Enable them in device settings.',
      );
    }
  }

  static Future<UserLocationData> getCurrentUserLocation() async {
    await requestLocationPermission();
    await ensureLocationServicesEnabled();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final city = await _resolveCityName(
      position.latitude,
      position.longitude,
    );

    return UserLocationData(
      coordinate: GeoCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      city: city,
    );
  }

  static Future<String> _resolveCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '';
      final p = placemarks.first;
      for (final part in [
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        final trimmed = part?.trim() ?? '';
        if (trimmed.isNotEmpty) return trimmed;
      }
    } catch (_) {
      // Geocoding can fail offline or on unsupported platforms.
    }
    return '';
  }

  /// Firestore fields to merge when saving a resolved location.
  static Map<String, dynamic> firestoreFields(
    UserLocationData data, {
    String? cityOverride,
  }) {
    final city = cityOverride?.trim();
    return {
      'location': GeoPoint(
        data.coordinate.latitude,
        data.coordinate.longitude,
      ),
      'city': (city != null && city.isNotEmpty) ? city : data.city,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    };
  }
}
