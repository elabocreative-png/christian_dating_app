import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth session stream for the app gate.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Signed-in user's uid, or null when signed out. Presentation-layer reads use
/// this instead of touching FirebaseAuth directly.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (user) => user?.uid,
        orElse: () => null,
      );
});

/// Live Firestore user document for profile completion checks.
final userProfileStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  },
);

/// Whether the signed-in user's profile is marked complete in Firestore.
final profileCompleteProvider = Provider.family<bool?, String>((ref, uid) {
  final profileAsync = ref.watch(userProfileStreamProvider(uid));
  return profileAsync.when(
    loading: () => null,
    error: (error, stackTrace) => false,
    data: (snap) {
      final data = snap.data();
      return data?['profileComplete'] == true;
    },
  );
});
