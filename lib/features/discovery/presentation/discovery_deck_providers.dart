import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/nearby_user.dart';

/// Nearby users for the signed-in viewer's current discovery filters/mode.
final discoveryDeckProvider =
    FutureProvider.autoDispose.family<List<NearbyUser>, String>((ref, uid) async {
  return ref.read(discoveryRepositoryProvider).fetchNearbyUsers(uid);
});

void invalidateDiscoveryDeck(WidgetRef ref, String uid) {
  ref.invalidate(discoveryDeckProvider(uid));
}

Future<List<NearbyUser>> fetchDiscoveryDeck(WidgetRef ref, String uid) {
  invalidateDiscoveryDeck(ref, uid);
  return ref.read(discoveryDeckProvider(uid).future);
}
