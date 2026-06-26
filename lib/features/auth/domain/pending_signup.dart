import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds email/password during onboarding before Firebase Auth account creation.
class PendingSignupState {
  const PendingSignupState({this.email, this.password});

  final String? email;
  final String? password;

  bool get isActive => email != null && password != null;
}

class PendingSignupNotifier extends Notifier<PendingSignupState> {
  @override
  PendingSignupState build() => const PendingSignupState();

  void start(String email, String password) {
    state = PendingSignupState(
      email: email.trim(),
      password: password,
    );
  }

  void clear() {
    state = const PendingSignupState();
  }
}

final pendingSignupProvider =
    NotifierProvider<PendingSignupNotifier, PendingSignupState>(
  PendingSignupNotifier.new,
);
