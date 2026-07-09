import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/matches/domain/match_id.dart';

void main() {
  group('matchIdForUsers', () {
    test('sorts user ids lexicographically', () {
      expect(matchIdForUsers('user-b', 'user-a'), 'user-a_user-b');
      expect(matchIdForUsers('user-a', 'user-b'), 'user-a_user-b');
    });

    test('is stable for identical ids', () {
      expect(matchIdForUsers('same', 'same'), 'same_same');
    });
  });
}
