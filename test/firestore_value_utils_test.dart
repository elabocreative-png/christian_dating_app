import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';

void main() {
  group('firestoreDateTimeFrom', () {
    test('returns DateTime values unchanged', () {
      final dt = DateTime.utc(2026, 3, 1, 12);
      expect(firestoreDateTimeFrom(dt), dt);
    });

    test('returns null for unsupported values', () {
      expect(firestoreDateTimeFrom(null), isNull);
      expect(firestoreDateTimeFrom('2026-01-01'), isNull);
      expect(firestoreDateTimeFrom(123), isNull);
    });
  });

  group('firestoreMillisFrom', () {
    test('returns epoch millis for DateTime', () {
      final dt = DateTime.utc(2026, 3, 1);
      expect(firestoreMillisFrom(dt), dt.millisecondsSinceEpoch);
    });

    test('returns 0 when value is missing or unparsable', () {
      expect(firestoreMillisFrom(null), 0);
      expect(firestoreMillisFrom('bad'), 0);
    });
  });
}
