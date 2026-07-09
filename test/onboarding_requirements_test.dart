import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/onboarding/onboarding_requirements.dart';
import 'package:christian_dating_app/core/constants/gender_options.dart';

void main() {
  group('OnboardingRequirements.validateName', () {
    test('rejects empty and too-short names', () {
      expect(OnboardingRequirements.validateName(''), isNotNull);
      expect(OnboardingRequirements.validateName('  '), isNotNull);
      expect(OnboardingRequirements.validateName('A'), isNotNull);
    });

    test('accepts valid names', () {
      expect(OnboardingRequirements.validateName('Alex'), isNull);
      expect(OnboardingRequirements.validateName('  Jo  '), isNull);
    });
  });

  group('OnboardingRequirements.validateBirthday', () {
    test('rejects under 18 and over 80', () {
      expect(OnboardingRequirements.validateBirthday(17), isNotNull);
      expect(OnboardingRequirements.validateBirthday(81), isNotNull);
      expect(OnboardingRequirements.validateBirthday(null), isNotNull);
    });

    test('accepts valid ages', () {
      expect(OnboardingRequirements.validateBirthday(18), isNull);
      expect(OnboardingRequirements.validateBirthday(40), isNull);
    });
  });

  group('OnboardingRequirements.validateGender', () {
    test('rejects unknown gender', () {
      expect(OnboardingRequirements.validateGender(null), isNotNull);
      expect(OnboardingRequirements.validateGender('Other'), isNotNull);
    });

    test('accepts canonical genders', () {
      expect(OnboardingRequirements.validateGender(kGenderMale), isNull);
      expect(OnboardingRequirements.validateGender(kGenderFemale), isNull);
    });
  });

  group('OnboardingRequirements.validatePrompts', () {
    test('requires at least one non-empty answer', () {
      expect(
        OnboardingRequirements.validatePrompts([
          {'question': 'Faith?', 'answer': '   '},
        ]),
        isNotNull,
      );
      expect(
        OnboardingRequirements.validatePrompts([
          {'question': 'Faith?', 'answer': 'Central to my life'},
        ]),
        isNull,
      );
    });
  });

  group('OnboardingRequirements.meetsProfileCompletionCriteria', () {
    test('false when required fields missing', () {
      expect(
        OnboardingRequirements.meetsProfileCompletionCriteria({'name': 'Alex'}),
        isFalse,
      );
    });

    test('true for complete onboarding profile', () {
      expect(
        OnboardingRequirements.meetsProfileCompletionCriteria({
          'name': 'Alex',
          'age': 28,
          'denomination': 'Baptist',
          'lookingFor': 'Friendship',
          'city': 'Austin',
          'prompts': [
            {'question': 'Faith?', 'answer': 'Yes'},
          ],
        }),
        isTrue,
      );
    });
  });
}
