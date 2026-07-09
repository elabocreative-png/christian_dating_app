import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/discovery/domain/account_visibility.dart';

void main() {
  group('isAccountDeactivated', () {
    test('true when accountDeactivated flag is set', () {
      expect(
        isAccountDeactivated({'accountDeactivated': true}),
        isTrue,
      );
    });

    test('false when flag missing or false', () {
      expect(isAccountDeactivated(null), isFalse);
      expect(isAccountDeactivated({}), isFalse);
      expect(
        isAccountDeactivated({'accountDeactivated': false}),
        isFalse,
      );
    });
  });
}
