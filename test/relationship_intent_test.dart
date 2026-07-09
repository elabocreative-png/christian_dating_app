import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/constants/relationship_intent.dart';

void main() {
  group('displayLookingForLabel', () {
    test('defaults empty and null to Friendship', () {
      expect(displayLookingForLabel(null), kDefaultLookingFor);
      expect(displayLookingForLabel(''), kDefaultLookingFor);
      expect(displayLookingForLabel('   '), kDefaultLookingFor);
    });

    test('canonicalizes legacy Serious Relationship label', () {
      expect(displayLookingForLabel('Serious Relationship'), 'Relationship');
    });

    test('returns trimmed canonical values', () {
      expect(displayLookingForLabel(' Marriage '), 'Marriage');
    });
  });

  group('resolvedLookingForForSave', () {
    test('defaults empty to Friendship', () {
      expect(resolvedLookingForForSave(null), kDefaultLookingFor);
      expect(resolvedLookingForForSave(''), kDefaultLookingFor);
    });

    test('canonicalizes legacy value for save', () {
      expect(
        resolvedLookingForForSave('Serious Relationship'),
        'Relationship',
      );
    });
  });

  group('isValidLookingFor', () {
    test('accepts canonical options and legacy alias', () {
      for (final option in kLookingForOptions) {
        expect(isValidLookingFor(option), isTrue);
      }
      expect(isValidLookingFor('Serious Relationship'), isTrue);
    });

    test('rejects unknown values', () {
      expect(isValidLookingFor(null), isFalse);
      expect(isValidLookingFor(''), isFalse);
      expect(isValidLookingFor('Casual'), isFalse);
    });
  });
}
