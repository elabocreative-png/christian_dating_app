import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/utils/geo_utils.dart';

void main() {
  group('parseUserGeoPoint', () {
    test('returns null for null or invalid values', () {
      expect(parseUserGeoPoint(null), isNull);
      expect(parseUserGeoPoint('invalid'), isNull);
      expect(parseUserGeoPoint({'latitude': 'bad', 'longitude': 1}), isNull);
    });

    test('parses GeoCoordinate unchanged', () {
      const coord = GeoCoordinate(latitude: 1.5, longitude: 2.5);
      expect(parseUserGeoPoint(coord), coord);
    });

    test('parses Firestore GeoPoint', () {
      final point = GeoPoint(40.7, -74.0);
      final parsed = parseUserGeoPoint(point);
      expect(parsed?.latitude, closeTo(40.7, 0.001));
      expect(parsed?.longitude, closeTo(-74.0, 0.001));
    });

    test('parses latitude/longitude and lat/lng maps', () {
      final fromLongKeys = parseUserGeoPoint({
        'latitude': 40.7128,
        'longitude': -74.0060,
      });
      expect(fromLongKeys?.latitude, closeTo(40.7128, 0.0001));
      expect(fromLongKeys?.longitude, closeTo(-74.0060, 0.0001));

      final fromShortKeys = parseUserGeoPoint({'lat': 51.5, 'lng': -0.12});
      expect(fromShortKeys?.latitude, 51.5);
      expect(fromShortKeys?.longitude, -0.12);
    });
  });

  group('distanceKmBetween', () {
    test('returns near-zero for identical coordinates', () {
      const coord = GeoCoordinate(latitude: 40.7128, longitude: -74.0060);
      expect(distanceKmBetween(coord, coord), closeTo(0, 0.001));
    });

    test('returns expected km between NYC and nearby point', () {
      const nyc = GeoCoordinate(latitude: 40.7128, longitude: -74.0060);
      const nearby = GeoCoordinate(latitude: 40.7580, longitude: -73.9855);
      final km = distanceKmBetween(nyc, nearby);
      expect(km, greaterThan(4));
      expect(km, lessThan(7));
    });
  });

  group('formatDistanceAway', () {
    test('formats very short distances', () {
      expect(formatDistanceAway(0.1), 'Less than 0.1 miles away');
      expect(formatDistanceAway(1.2), 'Less than 1 mile away');
    });

    test('formats sub-10 mile distances with one decimal', () {
      expect(formatDistanceAway(8.05), '5.0 miles away');
      expect(formatDistanceAway(3.22), '2.0 miles away');
    });

    test('formats longer distances as rounded miles', () {
      expect(formatDistanceAway(17.7), '11 miles away');
      expect(formatDistanceAway(80.47), '50 miles away');
    });
  });

  group('formatDistanceKmShort', () {
    test('formats sub-km and rounded km labels', () {
      expect(formatDistanceKmShort(0.5), 'Less than 1 km');
      expect(formatDistanceKmShort(4.6), '5 km');
    });
  });

  group('profile location labels', () {
    test('profileCityLabel trims whitespace', () {
      expect(profileCityLabel({'city': '  Lusaka  '}), 'Lusaka');
      expect(profileCityLabel({}), '');
      expect(hasProfileCityLabel({'city': 'NYC'}), isTrue);
      expect(hasProfileCityLabel({'city': '  '}), isFalse);
    });

    test('distanceAwayLabel reads distanceKm from profile', () {
      expect(distanceAwayLabel({'distanceKm': 8.05}), '5.0 miles away');
      expect(distanceAwayLabel({}), isNull);
      expect(hasDistanceAwayLabel({'distanceKm': 2}), isTrue);
    });

    test('distanceKmShortLabel reads distanceKm from profile', () {
      expect(distanceKmShortLabel({'distanceKm': 4.2}), '4 km');
      expect(distanceKmShortLabel({}), isNull);
    });

    test('locationHeroLabel uses city only', () {
      expect(
        locationHeroLabel({'city': 'Boston', 'distanceKm': 5}),
        'Boston',
      );
      expect(hasLocationHeroLabel({'city': 'Boston'}), isTrue);
    });

    test('profileLocationPillLabel combines distance and city', () {
      expect(
        profileLocationPillLabel({'city': 'Lusaka', 'distanceKm': 8.05}),
        '5.0 miles away. Lusaka',
      );
      expect(
        profileLocationPillLabel({'city': 'Lusaka'}, distanceKm: 8.05),
        '5.0 miles away. Lusaka',
      );
      expect(
        profileLocationPillLabel({'distanceKm': 8.05}),
        '5.0 miles away',
      );
      expect(profileLocationPillLabel({'city': 'Lusaka'}), 'Lusaka');
      expect(profileLocationPillLabel({}), isNull);
    });
  });
}
