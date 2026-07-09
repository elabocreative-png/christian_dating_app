import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/settings/data/issue_report_repository.dart';

void main() {
  group('IssueReportRepository.submit', () {
    test('returns false for blank description', () async {
      final repo = IssueReportRepository();
      expect(
        await repo.submit(uid: 'uid-1', description: '   '),
        isFalse,
      );
    });
  });
}
