import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

/// Firebase Auth session stream for the app gate.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Signed-in user's uid, or null when signed out. Presentation-layer reads use
/// this instead of touching FirebaseAuth directly.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (user) => user?.uid,
        orElse: () => null,
      );
});

/// Live profile map for [uid]; emits null when the document is absent.
final userProfileStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});

/// Whether the signed-in user's profile is marked complete in Firestore.
final profileCompleteProvider = Provider.family<bool?, String>((ref, uid) {
  final profileAsync = ref.watch(userProfileStreamProvider(uid));
  return profileAsync.when(
    loading: () => null,
    error: (error, stackTrace) => false,
    data: (data) => data?['profileComplete'] == true,
  );
});
