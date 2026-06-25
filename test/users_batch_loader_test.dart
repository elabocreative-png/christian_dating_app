import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/services/users_batch_loader.dart';

void main() {
  test('UsersBatchLoader.fetchByIds returns empty map for no ids', () async {
    final result = await UsersBatchLoader.fetchByIds([]);
    expect(result, isEmpty);
  });

  test('UsersBatchLoader.fetchByIds ignores empty id strings', () async {
    final result = await UsersBatchLoader.fetchByIds(['', '  ']);
    expect(result, isEmpty);
  });
}
