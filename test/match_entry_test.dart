import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

void main() {
  group('matchSortMillis', () {
    test('prefers lastMessageAt over createdAt', () {
      final last = DateTime.utc(2026, 1, 2);
      final created = DateTime.utc(2026, 1, 1);
      expect(
        matchSortMillis({
          'lastMessageAt': last,
          'createdAt': created,
        }),
        last.millisecondsSinceEpoch,
      );
    });

    test('falls back to createdAt when no last message', () {
      final created = DateTime.utc(2026, 1, 1);
      expect(
        matchSortMillis({
          'createdAt': created,
        }),
        created.millisecondsSinceEpoch,
      );
    });

    test('returns 0 when no timestamps', () {
      expect(matchSortMillis({}), 0);
    });
  });
}
