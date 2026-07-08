import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

/// Stable cache key for batch profile loads (sorted, deduped ids).
String profilesByIdsCacheKey(Iterable<String> userIds) {
  final unique = userIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return unique.join(',');
}

/// One-shot batch profile load keyed by [profilesByIdsCacheKey].
final profilesByIdsProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, dynamic>>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return {};
  return ref
      .watch(profileRepositoryProvider)
      .fetchProfilesByIds(idsKey.split(','));
});

/// Live profile document for the signed-in user (null when signed out or
/// the document does not exist yet).
final myProfileProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});
