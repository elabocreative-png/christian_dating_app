import 'package:flutter/foundation.dart';

/// Holds email/password during onboarding before Firebase Auth account creation.
class PendingSignup extends ChangeNotifier {
  PendingSignup._();

  static final PendingSignup instance = PendingSignup._();

  String? _email;
  String? _password;

  bool get isActive => _email != null && _password != null;
  String? get email => _email;
  String? get password => _password;

  void start(String email, String password) {
    _email = email.trim();
    _password = password;
    notifyListeners();
  }

  void clear() {
    if (_email == null && _password == null) return;
    _email = null;
    _password = null;
    notifyListeners();
  }
}
