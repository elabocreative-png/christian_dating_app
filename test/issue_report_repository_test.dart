import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/settings/data/issue_report_repository.dart';

void main() {
  group('IssueReportRepository guards', () {
    test('submit returns false for blank description', () async {
      final repo = IssueReportRepository(firestore: FakeFirebaseFirestore());
      expect(
        await repo.submit(uid: 'uid-1', description: '   '),
        isFalse,
      );
    });
  });

  group('IssueReportRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore firestore;
    late IssueReportRepository repo;
    const uid = 'user-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = IssueReportRepository(firestore: firestore);
    });

    test('submit persists trimmed text report without image', () async {
      final ok = await repo.submit(
        uid: uid,
        description: '  App crashed on chat screen  ',
      );
      expect(ok, isTrue);

      final snapshot = await firestore.collection('issue_reports').get();
      expect(snapshot.docs, hasLength(1));

      final data = snapshot.docs.single.data();
      expect(data['userId'], uid);
      expect(data['description'], 'App crashed on chat screen');
      expect(data['source'], 'settings');
      expect(data.containsKey('imageUrl'), isFalse);
      expect(data['createdAt'], isNotNull);
    });
  });
}
