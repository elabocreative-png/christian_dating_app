import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

void main() {
  test('ProfileRepository.fetchProfilesByIds returns empty map for no ids',
      () async {
    final repo = ProfileRepository();
    final result = await repo.fetchProfilesByIds([]);
    expect(result, isEmpty);
  });

  test('ProfileRepository.fetchProfilesByIds ignores empty id strings',
      () async {
    final repo = ProfileRepository();
    final result = await repo.fetchProfilesByIds(['', '  ']);
    expect(result, isEmpty);
  });
}
