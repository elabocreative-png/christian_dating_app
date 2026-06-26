import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-session read matches so bottom-nav badges update before Firestore syncs.
class MatchReadStateNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markRead(String matchId) {
    if (!state.contains(matchId)) {
      state = {...state, matchId};
    }
  }

  void clear() {
    if (state.isNotEmpty) {
      state = <String>{};
    }
  }
}

final matchReadStateProvider =
    NotifierProvider<MatchReadStateNotifier, Set<String>>(
  MatchReadStateNotifier.new,
);
