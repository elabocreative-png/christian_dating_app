import 'package:flutter/foundation.dart';

/// In-session read matches so bottom-nav badges update before Firestore syncs.
class MatchReadState extends ChangeNotifier {
  MatchReadState._();

  static final MatchReadState instance = MatchReadState._();

  final Set<String> _readMatchIds = <String>{};

  Set<String> get readMatchIds => Set.unmodifiable(_readMatchIds);

  void markRead(String matchId) {
    if (_readMatchIds.add(matchId)) {
      notifyListeners();
    }
  }

  void clear() {
    if (_readMatchIds.isEmpty) return;
    _readMatchIds.clear();
    notifyListeners();
  }
}
