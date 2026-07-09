import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/profile/domain/profile_completion.dart';

void main() {
  group('profileCompletionFraction', () {
    test('returns 0 for empty profile', () {
      expect(profileCompletionFraction({}), 0);
    });

    test('counts filled core fields and prompt answer', () {
      final fraction = profileCompletionFraction({
        'name': 'Alex',
        'age': 28,
        'city': 'Austin',
        'denomination': 'Baptist',
        'photos': ['https://example.com/1.jpg'],
        'prompts': [
          {'question': 'Faith?', 'answer': 'Central to my life'},
        ],
      });
      expect(fraction, 1.0);
    });

    test('partial profile returns fraction between 0 and 1', () {
      final fraction = profileCompletionFraction({
        'name': 'Alex',
        'age': 28,
        'prompts': [],
      });
      expect(fraction, greaterThan(0));
      expect(fraction, lessThan(1));
    });
  });

  group('isProfileFullyComplete', () {
    test('true when fraction is 1', () {
      expect(
        isProfileFullyComplete({
          'name': 'Alex',
          'age': 28,
          'city': 'Austin',
          'denomination': 'Baptist',
          'photos': ['https://example.com/1.jpg'],
          'prompts': [
            {'question': 'Faith?', 'answer': 'Yes'},
          ],
        }),
        isTrue,
      );
    });

    test('true when onboarding criteria met even if city missing', () {
      expect(
        isProfileFullyComplete({
          'name': 'Alex',
          'age': 28,
          'denomination': 'Baptist',
          'lookingFor': 'Friendship',
          'latitude': 30.27,
          'prompts': [
            {'question': 'Faith?', 'answer': 'Yes'},
          ],
        }),
        isTrue,
      );
    });

    test('false for sparse profile', () {
      expect(
        isProfileFullyComplete({'name': 'Alex'}),
        isFalse,
      );
    });
  });
}
