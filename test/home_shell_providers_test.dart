import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/navigation/home_shell_providers.dart';

void main() {
  group('HomeShellTabIndexNotifier', () {
    test('setIndex updates selected tab', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final notifier = container.read(homeShellTabIndexProvider.notifier);
      expect(container.read(homeShellTabIndexProvider), 0);

      notifier.setIndex(2);
      expect(container.read(homeShellTabIndexProvider), 2);
    });

    test('setIndex no-ops when index unchanged', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final notifier = container.read(homeShellTabIndexProvider.notifier);
      notifier.setIndex(1);
      notifier.setIndex(1);

      expect(container.read(homeShellTabIndexProvider), 1);
    });
  });
}
