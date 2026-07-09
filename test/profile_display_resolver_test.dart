import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/constants/church_attendance_options.dart';
import 'package:christian_dating_app/core/constants/denomination_options.dart';
import 'package:christian_dating_app/core/constants/faith_options.dart';
import 'package:christian_dating_app/core/constants/gender_options.dart';
import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/features/discovery/domain/profile_display_resolver.dart';

void main() {
  group('ProfileDisplayResolver.resolve', () {
    const profileUserId = 'stable-user-id';

    test('uses saved profile values when present', () {
      final values = ProfileDisplayResolver.resolve(
        user: {
          'lookingFor': 'Marriage',
          'faithLevel': 'Strong',
          'gender': kGenderFemale,
          'churchAttendance': 'Attend weekly',
          'denomination': 'Baptist',
          'distanceKm': 5.5,
        },
        profileUserId: profileUserId,
        locationServicesEnabled: true,
      );

      expect(values.lookingFor, 'Marriage');
      expect(values.faithLevel, 'Strong');
      expect(values.gender, kGenderFemale);
      expect(values.churchAttendance, 'Attend weekly');
      expect(values.denomination, 'Baptist');
      expect(values.heroDistanceKm, 5.5);
      expect(values.distanceKm, 5.5);
    });

    test('hides distance when location services are disabled', () {
      final values = ProfileDisplayResolver.resolve(
        user: {'distanceKm': 12},
        profileUserId: profileUserId,
        locationServicesEnabled: false,
      );

      expect(values.heroDistanceKm, 12);
      expect(values.distanceKm, isNull);
    });

    test('fills missing fields with stable placeholders for same user id', () {
      final first = ProfileDisplayResolver.resolve(
        user: const {},
        profileUserId: profileUserId,
        locationServicesEnabled: true,
      );
      final second = ProfileDisplayResolver.resolve(
        user: const {},
        profileUserId: profileUserId,
        locationServicesEnabled: true,
      );

      expect(second.lookingFor, first.lookingFor);
      expect(second.faithLevel, first.faithLevel);
      expect(second.gender, first.gender);
      expect(second.churchAttendance, first.churchAttendance);
      expect(second.denomination, first.denomination);
      expect(second.heroDistanceKm, first.heroDistanceKm);
    });

    test('placeholder values come from canonical option lists', () {
      final values = ProfileDisplayResolver.resolve(
        user: const {},
        profileUserId: profileUserId,
        locationServicesEnabled: true,
      );

      expect(kLookingForOptions, contains(values.lookingFor));
      expect(kFaithLevelOptions, contains(values.faithLevel));
      expect(kGenderOptions, contains(values.gender));
      expect(kChurchAttendanceOptions, contains(values.churchAttendance));
      expect(kDenominationOptions, contains(values.denomination));
      expect(values.heroDistanceKm, inInclusiveRange(2, 30));
    });

    test('canonicalizes legacy lookingFor alias', () {
      final values = ProfileDisplayResolver.resolve(
        user: {'lookingFor': 'Serious Relationship'},
        profileUserId: profileUserId,
        locationServicesEnabled: false,
      );

      expect(values.lookingFor, 'Relationship');
    });

    test('seeds placeholders from name and email when user id missing', () {
      final first = ProfileDisplayResolver.resolve(
        user: {'name': 'Alex', 'email': 'alex@example.com'},
        locationServicesEnabled: false,
      );
      final second = ProfileDisplayResolver.resolve(
        user: {'name': 'Alex', 'email': 'alex@example.com'},
        locationServicesEnabled: false,
      );

      expect(second.gender, first.gender);
      expect(second.heroDistanceKm, first.heroDistanceKm);
    });
  });

  group('gender display helpers', () {
    test('maps female and male labels icons and emoji', () {
      expect(genderDisplayLabel(kGenderFemale), 'Woman');
      expect(genderDisplayLabel(kGenderMale), 'Man');
      expect(genderDisplayEmoji(kGenderFemale), '👩');
      expect(genderDisplayEmoji(kGenderMale), '👨');
      expect(genderDisplayIcon(kGenderFemale), Icons.face_3);
      expect(genderDisplayIcon(kGenderMale), Icons.face_6);
    });
  });
}
