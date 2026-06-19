import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/discovery_preferences.dart';
import 'package:christian_dating_app/gender_options.dart';

void main() {
  group('interestedInForDiscoveryDeck', () {
    test('dating shows opposite gender for women', () {
      expect(
        interestedInForDiscoveryDeck(
          kDiscoveryModeDating,
          viewerGender: kGenderFemale,
        ),
        kInterestedInMen,
      );
    });

    test('dating shows opposite gender for men', () {
      expect(
        interestedInForDiscoveryDeck(
          kDiscoveryModeDating,
          viewerGender: kGenderMale,
        ),
        kInterestedInWomen,
      );
    });

    test('social shows all genders', () {
      expect(
        interestedInForDiscoveryDeck(
          kDiscoveryModeSocial,
          viewerGender: kGenderMale,
        ),
        kInterestedInAnyone,
      );
    });
  });

  group('shouldExcludeUserFromDiscoveryDeck', () {
    test('dating like hides from social and dating decks', () {
      expect(
        shouldExcludeUserFromDiscoveryDeck(
          deckMode: kDiscoveryModeSocial,
          interactionMode: kDiscoveryModeDating,
        ),
        isTrue,
      );
      expect(
        shouldExcludeUserFromDiscoveryDeck(
          deckMode: kDiscoveryModeDating,
          interactionMode: kDiscoveryModeDating,
        ),
        isTrue,
      );
    });

    test('social wave hides from dating and social decks', () {
      expect(
        shouldExcludeUserFromDiscoveryDeck(
          deckMode: kDiscoveryModeDating,
          interactionMode: kDiscoveryModeSocial,
        ),
        isTrue,
      );
      expect(
        shouldExcludeUserFromDiscoveryDeck(
          deckMode: kDiscoveryModeSocial,
          interactionMode: kDiscoveryModeSocial,
        ),
        isTrue,
      );
    });

    test('no interaction does not exclude', () {
      expect(
        shouldExcludeUserFromDiscoveryDeck(
          deckMode: kDiscoveryModeDating,
          interactionMode: null,
        ),
        isFalse,
      );
    });
  });

  group('interactionModeByUserId', () {
    test('prefers outgoing like mode over incoming for matches', () {
      final modes = interactionModeByUserId(
        outgoingLikes: [
          {
            'toUserId': 'u2',
            'discoveryMode': kDiscoveryModeDating,
          },
        ],
        incomingLikes: [
          {
            'fromUserId': 'u2',
            'discoveryMode': kDiscoveryModeSocial,
          },
        ],
        matchedUserIds: {'u2'},
      );

      expect(modes['u2'], kDiscoveryModeDating);
    });

    test('uses incoming like mode for matches without outgoing like', () {
      final modes = interactionModeByUserId(
        outgoingLikes: const [],
        incomingLikes: [
          {
            'fromUserId': 'u3',
            'discoveryMode': kDiscoveryModeSocial,
          },
        ],
        matchedUserIds: {'u3'},
      );

      expect(modes['u3'], kDiscoveryModeSocial);
    });
  });
}
