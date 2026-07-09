import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected index of the main [StatefulShellRoute] (0 = Discover … 3 = Profile).
class HomeShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (state != index) {
      state = index;
    }
  }
}

final homeShellTabIndexProvider =
    NotifierProvider<HomeShellTabIndexNotifier, int>(
  HomeShellTabIndexNotifier.new,
);
