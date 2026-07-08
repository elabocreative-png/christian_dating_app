import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/profile/data/profile_image_repository.dart';

void main() {
  test('uploadProfilePhotosParallel returns empty list for no files', () async {
    final repo = ProfileImageRepository();
    final result = await repo.uploadProfilePhotosParallel([], 'uid-1');
    expect(result, isEmpty);
  });
}
