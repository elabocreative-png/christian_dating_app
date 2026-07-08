import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/features/profile/data/location_service.dart';

void main() {
  group('LocationService.firestoreFields', () {
    test('uses city override when provided', () {
      final service = LocationService();
      final data = UserLocationData(
        coordinate: GeoCoordinate(latitude: -15.39, longitude: 28.32),
        city: 'Lusaka',
      );

      final fields = service.firestoreFields(data, cityOverride: '  Kitwe  ');

      expect(fields['city'], 'Kitwe');
      expect(fields['location'], isA<GeoPoint>());
      final point = fields['location']! as GeoPoint;
      expect(point.latitude, closeTo(-15.39, 0.001));
      expect(point.longitude, closeTo(28.32, 0.001));
      expect(fields['locationUpdatedAt'], isA<FieldValue>());
    });

    test('falls back to resolved city when override is blank', () {
      final service = LocationService();
      final data = UserLocationData(
        coordinate: GeoCoordinate(latitude: 1, longitude: 2),
        city: 'Lusaka',
      );

      final fields = service.firestoreFields(data, cityOverride: '   ');

      expect(fields['city'], 'Lusaka');
    });
  });
}
