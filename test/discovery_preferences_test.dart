import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/constants/gender_options.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';

void main() {
  group('discovery distance helpers', () {
    test('discoveryMilesFromKm maps km to nearest stop', () {
      expect(discoveryMilesFromKm(32), 20);
      expect(discoveryMilesFromKm(300), -1);
    });

    test('discoveryKmFromMilesStop converts miles back to km', () {
      expect(discoveryKmFromMilesStop(20), closeTo(32.2, 0.1));
      expect(discoveryKmFromMilesStop(-1), 300);
    });

    test('discoveryMilesStopIndex resolves slider index', () {
      expect(discoveryMilesStopIndex(40), 2);
      expect(discoveryMilesStopIndex(-1), kDistanceMilesStops.length - 1);
    });

    test('discoveryDistanceStopLabel formats max stop', () {
      expect(discoveryDistanceStopLabel(-1), 'Max');
      expect(discoveryDistanceStopLabel(30), '30');
    });
  });

  group('profileMatchesInterestedIn', () {
    test('Anyone matches all genders', () {
      expect(
        profileMatchesInterestedIn(
          kInterestedInAnyone,
          {'gender': kGenderMale},
        ),
        isTrue,
      );
    });

    test('Men/Women filter by canonical gender', () {
      expect(
        profileMatchesInterestedIn(
          kInterestedInMen,
          {'gender': kGenderMale},
        ),
        isTrue,
      );
      expect(
        profileMatchesInterestedIn(
          kInterestedInMen,
          {'gender': kGenderFemale},
        ),
        isFalse,
      );
      expect(
        profileMatchesInterestedIn(
          kInterestedInWomen,
          {'gender': kGenderFemale},
        ),
        isTrue,
      );
    });
  });

  group('resolvedInterestedInForMode', () {
    test('dating defaults to opposite gender when unset', () {
      expect(
        resolvedInterestedInForMode(
          null,
          kDiscoveryModeDating,
          viewerGender: kGenderFemale,
        ),
        kInterestedInMen,
      );
    });

    test('social defaults to Anyone', () {
      expect(
        resolvedInterestedInForMode(null, kDiscoveryModeSocial),
        kInterestedInAnyone,
      );
    });
  });

  group('interestedInForModeSwitch', () {
    test('switching to social returns Anyone', () {
      expect(
        interestedInForModeSwitch(
          newMode: kDiscoveryModeSocial,
          currentInterestedIn: kInterestedInMen,
          viewerGender: kGenderFemale,
        ),
        kInterestedInAnyone,
      );
    });

    test('switching to dating maps Anyone to opposite gender', () {
      expect(
        interestedInForModeSwitch(
          newMode: kDiscoveryModeDating,
          currentInterestedIn: kInterestedInAnyone,
          viewerGender: kGenderMale,
        ),
        kInterestedInWomen,
      );
    });
  });
}
